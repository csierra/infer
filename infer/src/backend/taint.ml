(*
 * Copyright (c) 2016 - present Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *)

open! Utils

module L = Logging

open PatternMatch

(* list of sources that return a tainted value *)
let sources = [
  (* for testing only *)
  {
    classname = "com.facebook.infer.models.InferTaint";
    method_name = "inferSecretSource";
    ret_type = "java.lang.Object";
    params = [];
    is_static = true;
    taint_kind = Sil.Tk_unknown;
    language = Config.Java;
  };
  {
    classname = "com.facebook.infer.models.InferTaint";
    method_name = "inferSecretSourceUndefined";
    ret_type = "java.lang.Object";
    params = [];
    is_static = true;
    taint_kind = Sil.Tk_unknown;
    language = Config.Java
  };
  (* actual specs *)
  {
    classname = "android.content.SharedPreferences";
    method_name = "getString";
    ret_type = "java.lang.String";
    params = ["java.lang.String"; "java.lang.String"];
    is_static = false;
    taint_kind = Sil.Tk_shared_preferences_data;
    language = Config.Java
  };
  (* === iOS === *)
  {
    classname = "NSHTTPCookie";
    method_name = "value";
    ret_type = "NSString *";
    params = [];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Clang
  };

] @ FbTaint.sources

(* list of (sensitive sinks, zero-indexed numbers of parameters that should not be tainted). note:
   index 0 means "the first non-this/self argument"; we currently don't have a way to say "this/self
   should not be tainted" with this form of specification *)
let sinks = [
  (* for testing only *)
  ({
    classname = "com.facebook.infer.models.InferTaint";
    method_name = "inferSensitiveSink";
    ret_type = "void";
    params = ["java.lang.Object"];
    is_static = true;
    taint_kind = Sil.Tk_unknown;
    language = Config.Java
  }, [0]);
  ({
    classname = "com.facebook.infer.models.InferTaint";
    method_name = "inferSensitiveSinkUndefined";
    ret_type = "void";
    params = ["java.lang.Object"];
    is_static = true;
    taint_kind = Sil.Tk_unknown;
    language = Config.Java
  }, [0]);
  (* actual specs *)
  ({
    classname = "android.util.Log";
    method_name = "d";
    ret_type = "int";
    params = ["java.lang.String"; "java.lang.String"];
    is_static = true;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java
  }, [0;1]);
  ({
    classname = "android.content.ContentResolver";
    method_name = "openInputStream";
    ret_type = "java.io.InputStream";
    params = ["android.net.Uri"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [1]);
  ({
    classname = "android.content.ContentResolver";
    method_name = "openOutputStream";
    ret_type = "java.io.OutputStream";
    params = ["android.net.Uri"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [0]);
  ({
    classname = "android.content.ContentResolver";
    method_name = "openOutputStream";
    ret_type = "java.io.OutputStream";
    params = ["android.net.Uri"; "java.lang.String"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [0]);
  ({
    classname = "android.content.ContentResolver";
    method_name = "openAssetFileDescriptor";
    ret_type = "android.content.res.AssetFileDescriptor";
    params = ["android.net.Uri"; "java.lang.String"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [0]);
  ({
    classname = "android.content.ContentResolver";
    method_name = "openAssetFileDescriptor";
    ret_type = "android.content.res.AssetFileDescriptor";
    params = ["android.net.Uri"; "java.lang.String"; "android.os.CancellationSignal"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [0]);
  ({
    classname = "android.content.ContentResolver";
    method_name = "openFileDescriptor";
    ret_type = "android.os.ParcelFileDescriptor";
    params = ["android.net.Uri"; "java.lang.String"; "android.os.CancellationSignal"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [0]);
  ({
    classname = "android.content.ContentResolver";
    method_name = "openFileDescriptor";
    ret_type = "android.os.ParcelFileDescriptor";
    params = ["android.net.Uri"; "java.lang.String"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [0]);
  ({
    classname = "android.content.ContentResolver";
    method_name = "openTypedAssetFileDescriptor";
    ret_type = "android.content.res.AssetFileDescriptor";
    params = ["android.net.Uri"; "java.lang.String"; "android.os.Bundle";
              "android.os.CancellationSignal"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [0]);
  ({
    classname = "android.content.ContentResolver";
    method_name = "openTypedAssetFileDescriptor";
    ret_type = "android.content.res.AssetFileDescriptor";
    params = ["android.net.Uri"; "java.lang.String"; "android.os.Bundle"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [0]);
  ({
    classname = "javax.servlet.ServletOutputStream";
    method_name = "print";
    ret_type = "void";
    params = ["java.lang.String"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [1]);
  ({
    classname = "javax.servlet.ServletOutputStream";
    method_name = "println";
    ret_type = "void";
    params = ["java.lang.String"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [1]);
  ({
    classname = "javax.servlet.jsp.JspWriter";
    method_name = "println";
    ret_type = "void";
    params = ["java.lang.String"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [1]);
  ({
    classname = "javax.servlet.jsp.JspWriter";
    method_name = "print";
    ret_type = "void";
    params = ["java.lang.String"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [1]);
  ({
    classname = "javax.servlet.jsp.JspWriter";
    method_name = "write";
    ret_type = "void";
    params = ["java.lang.String"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [1]);
  ({
    classname = "java.io.Writer";
    method_name = "write";
    ret_type = "void";
    params = ["java.lang.String"];
    is_static = false;
    taint_kind = Sil.Tk_privacy_annotation;
    language = Config.Java;
  }, [1]);
  (* === iOS === *)
  ({
    classname = "NSString";
    method_name = "stringWithFormat:";
    ret_type = "instancetype";
    params = [];
    is_static = true;
    taint_kind = Sil.Tk_unknown;
    language = Config.Clang;
  }, [-2]);
  ({
    classname = "NSString";
    method_name = "stringWithUTF8String:";
    ret_type = "instancetype";
    params = [];
    is_static = true;
    taint_kind = Sil.Tk_unknown;
    language = Config.Clang
  }, [-2]);
  ({
    classname = "NSString";
    method_name = "localizedStringWithFormat:";
    ret_type = "instancetype";
    params = [];
    is_static = true;
    taint_kind = Sil.Tk_unknown;
    language = Config.Clang
  }, [-2]);
  ({
    classname = "NSString";
    method_name = "initWithFormat:";
    ret_type = "instancetype";
    params = [];
    is_static = false;
    taint_kind = Sil.Tk_unknown;
    language = Config.Clang
  }, [-2]);
  ({
    classname = "NSString";
    method_name = "stringWithString:";
    ret_type = "instancetype";
    params = [];
    is_static = true;
    taint_kind = Sil.Tk_unknown;
    language = Config.Clang
  }, [0]);

  (*  ==== iOS for testing only ==== *)
  ({
    classname = "ExampleViewController";
    method_name = "loadURL:trackingCodes:";
    ret_type = "void";
    params = [];
    is_static = false;
    taint_kind = Sil.Tk_unknown;
    language = Config.Clang;
  }, [1]); (* it's instance method *)
] @ FbTaint.sinks

let functions_with_tainted_params = [
  (*  ==== iOS for testing only ==== *)
  ({
    classname = "ExampleDelegate";
    method_name = "application:openURL:sourceApplication:annotation:";
    ret_type = "BOOL";
    params = [];
    is_static = false; (* it's instance method *)
    taint_kind = Sil.Tk_unknown;
    language = Config.Clang;
  }, [2]);

  (* actual specs *)
  ({ (* This method is a source in iOS as it get as parameter
        a non trusted URL (openURL). The method the passes
        it around and this URL may arrive unsanitized to
        loadURL:trackingCodes: of FBWebViewController
        which uses the URL. *)
    classname = "AppDelegate";
    method_name = "application:openURL:sourceApplication:annotation:";
    ret_type = "BOOL";
    params = [];
    is_static = false; (* it's instance method *)
    taint_kind = Sil.Tk_integrity_annotation;
    language = Config.Clang;
  }, [2]);
] @ FbTaint.functions_with_tainted_params

(* turn string specificiation of Java method into a procname *)
let java_method_to_procname java_method =
  Procname.Java
    (Procname.java
       (Procname.split_classname java_method.classname)
       (Some (Procname.split_classname java_method.ret_type))
       java_method.method_name
       (IList.map Procname.split_classname java_method.params)
       (if java_method.is_static then Procname.Static else Procname.Non_Static))

(* turn string specificiation of an objc method into a procname *)
let objc_method_to_procname objc_method =
  let method_kind = Procname.objc_method_kind_of_bool (not objc_method.is_static) in
  let mangled = Procname.mangled_of_objc_method_kind method_kind in
  Procname.ObjC_Cpp
    (Procname.objc_cpp objc_method.classname objc_method.method_name mangled)

let taint_spec_to_taint_info taint_spec =
  let taint_source =
    match taint_spec.language with
    | Config.Clang -> objc_method_to_procname taint_spec
    | Config.Java -> java_method_to_procname taint_spec in
  { Sil.taint_source; taint_kind = taint_spec.taint_kind }

let sources =
  IList.map taint_spec_to_taint_info sources

let mk_pname_param_num methods =
  IList.map
    (fun (mname, param_num) -> taint_spec_to_taint_info mname, param_num)
    methods

let taint_sinks =
  mk_pname_param_num sinks

let func_with_tainted_params =
  mk_pname_param_num functions_with_tainted_params

let attrs_opt_get_annots = function
  | Some attrs -> attrs.ProcAttributes.method_annotation
  | None -> Sil.method_annotation_empty

let ends_with haystack needle =
    let length = String.length needle in
    let haystack_length = String.length haystack in
    let end_string = try 
	Some (String.sub haystack (haystack_length - length) length)
      with Invalid_argument(a) -> None in
    match end_string with 
    | Some s -> s = needle
    | None -> false


let is_liferay_service callee_pname =
  let service_endings = ["LocalServiceImpl"; "LocalService"; "Persistence"; "PersistenceImpl"; "LocalServiceUtil"; "ServiceUtil"] in
  match callee_pname with
  | Procname.Java(java_callee) ->
     let java_class_name = Procname.java_get_simple_class_name java_callee in
     IList.exists (ends_with java_class_name) service_endings
  | _ -> false
	   
(* TODO: return a taint kind *)
(** returns true if [callee_pname] returns a tainted value *)
let returns_tainted callee_pname callee_attrs_opt =
  let procname_matches taint_info =
    Procname.equal taint_info.Sil.taint_source callee_pname in
  try
    let taint_info = IList.find procname_matches sources in
    Some taint_info.Sil.taint_kind
  with Not_found ->
    let ret_annot, _ = attrs_opt_get_annots callee_attrs_opt in
    if Annotations.ia_is_integrity_source ret_annot
    then Some Sil.Tk_integrity_annotation
    else if Annotations.ia_is_privacy_source ret_annot
    then Some Sil.Tk_privacy_annotation
    else if is_liferay_service callee_pname
    then Some Sil.Tk_privacy_annotation
    else None

let find_callee taint_infos callee_pname =
  try
    Some
      (IList.find
         (fun (taint_info, _) -> Procname.equal taint_info.Sil.taint_source callee_pname)
         taint_infos)
  with Not_found -> None

(** returns list of zero-indexed argument numbers of [callee_pname] that may be tainted *)
let accepts_sensitive_params callee_pname callee_attrs_opt =
  match find_callee taint_sinks callee_pname with
  | None ->
      let _, param_annots = attrs_opt_get_annots callee_attrs_opt in
      let offset = if Procname.java_is_static callee_pname then 0 else 1 in
      let indices_and_annots =
        IList.mapi (fun param_num attr  -> param_num + offset, attr) param_annots in
      let tag_tainted_indices acc (index, attr) =
        if Annotations.ia_is_integrity_sink attr
        then (index, Sil.Tk_privacy_annotation) :: acc
        else if Annotations.ia_is_privacy_sink attr
        then (index, Sil.Tk_privacy_annotation) :: acc
        else acc in
      IList.fold_left tag_tainted_indices [] indices_and_annots
  | Some (taint_info, tainted_param_indices) ->
      IList.map (fun param_num -> param_num, taint_info.Sil.taint_kind) tainted_param_indices

(** returns list of zero-indexed parameter numbers of [callee_pname] that should be
    considered tainted during symbolic execution *)
let tainted_params callee_pname =
  match find_callee func_with_tainted_params callee_pname with
  | Some (taint_info, tainted_param_indices) ->
      IList.map (fun param_num -> param_num, taint_info.Sil.taint_kind) tainted_param_indices
  | None -> []

let has_taint_annotation fieldname struct_typ =
  let fld_has_taint_annot (fname, _, annot) =
    Ident.fieldname_equal fieldname fname &&
    (Annotations.ia_is_privacy_source annot || Annotations.ia_is_integrity_source annot) in
  IList.exists fld_has_taint_annot struct_typ.Sil.instance_fields ||
  IList.exists fld_has_taint_annot struct_typ.Sil.static_fields

(* add tainting attributes to a list of paramenters *)
let get_params_to_taint tainted_param_nums formal_params =
  let get_taint_kind index =
    try Some (IList.find (fun (taint_index, _) -> index = taint_index) tainted_param_nums)
    with Not_found -> None in
  let collect_params_to_taint params_to_taint_acc (index, param) =
    match get_taint_kind index with
    | Some (_, taint_kind) -> (param, taint_kind) :: params_to_taint_acc
    | None -> params_to_taint_acc in
  let numbered_params = IList.mapi (fun i param -> (i, param)) formal_params in
  IList.fold_left collect_params_to_taint [] numbered_params

(* add tainting attribute to a pvar in a prop *)
let add_tainting_attribute att pvar_param prop =
  IList.fold_left
    (fun prop_acc hpred ->
       match hpred with
       | Sil.Hpointsto (Sil.Lvar pvar, (Sil.Eexp (rhs, _)), _)
         when Pvar.equal pvar pvar_param ->
           L.d_strln ("TAINT ANALYSIS: setting taint/untaint attribute of parameter " ^
                      (Pvar.to_string pvar));
           Prop.add_or_replace_exp_attribute prop_acc rhs att
       | _ -> prop_acc)
    prop (Prop.get_sigma prop)


