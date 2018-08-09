(* This file is part of Learn-OCaml.
 *
 * Copyright (C) 2018 OCamlPro.
 *
 * Learn-OCaml is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * Learn-OCaml is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>. *)

(** This module defines the complete LearnOCaml API, with helpers for generating
    well-typed implementations of both the client and server side.

    - the [request] GADT gives all requests with their input and output types
    - the [response_codec] function gives the underlying encoding for responses
      to all requests
    - the [to_http_request] function maps the [request] type to HTTP requests
    - the [server_handler] function conversely maps inbound HTTP requests to the
      [request] type, and passes the results to a callback.
    - the [make_request] function takes a [request], and retrieves the
      well-typed response from the server
*)

type 'a token = Learnocaml_sync.Token.t

type student
type teacher

type _ request =
  | Static: string list -> string request
  | Version: unit -> string request
  | Create_token: student token option -> student token request
  | Create_teacher_token: teacher token -> teacher token request
  | Fetch_save: 'a token -> Learnocaml_sync.save_file request
  | Update_save:
      'a token * Learnocaml_sync.save_file ->
      Learnocaml_sync.save_file request
  | Exercise_index: 'a token -> Learnocaml_index.group_contents request
  (* | Exercise: Learnocaml_exercise.id -> Learnocaml_exercise.t request
   * | Lesson_index: unit -> (string * string) list request *)
  (** to help transition: do not use *)
  | Static_json: string * 'a Json_encoding.encoding -> 'a request
  | Invalid_request: string -> string request

type http_request = {
  meth: [ `GET | `POST of string];
  path: string list;
}

module type JSON_CODEC = sig
  val decode: 'a Json_encoding.encoding -> string -> 'a
  val encode: 'a Json_encoding.encoding -> 'a -> string
end

module type REQUEST_HANDLER = sig
  type 'resp ret

  val map_ret: ('a -> 'b) -> 'a ret -> 'b ret

  val callback: 'resp request -> 'resp ret
end

module Server: functor (Json: JSON_CODEC) (Rh: REQUEST_HANDLER) -> sig

  (** Helper to define a server: handles recognition of the incoming request, and
      encoding of the response. *)
  val handler: http_request -> string Rh.ret

end

module Client: functor (Json: JSON_CODEC) -> sig

  (** Helper to make a client request: handles encoding of the request and
      decoding of the response. *)
  val make_request:
    (http_request -> (string, 'a) result Lwt.t) ->
    'resp request -> ('resp, 'a) result Lwt.t

end
