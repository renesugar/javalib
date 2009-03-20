(*
 * This file is part of JavaLib
 * Copyright (c)2007, 2008 Tiphaine Turpin (Université de Rennes 1)
 * Copyright (c)2007, 2008 Laurent Hubert (CNRS)
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation, either version 3 of
 * the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program.  If not, see 
 * <http://www.gnu.org/licenses/>.
 *)

(** Prints data from {!JClass} to a provided output.*)


val opcode : JClass.opcode -> string
val dump_code : 'a IO.output -> 'b -> JClass.code -> unit
val dump_cfield :
  'a IO.output -> JBasics.constant array -> JClass.class_field -> unit
val dump_ifield :
  'a IO.output -> JBasics.constant array -> JClass.interface_field -> unit
val dump_cmethod :
  'a IO.output -> JBasics.constant array -> JClass.concrete_method -> unit
val dump_amethod :
  'a IO.output -> JBasics.constant array -> JClass.abstract_method -> unit
val dump_acmethod :
  'a IO.output -> JBasics.constant array -> JClass.jmethod -> unit
val dump : 'a IO.output -> JClass.interface_or_class -> unit
