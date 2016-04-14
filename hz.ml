open Lwt.Infix

module Model = struct

  module HType = struct 
    type t = 
        Num of int
      | Arrow of t * t 
      | Hole 
  end

  module HExp = struct
    type t = 
      | Asc of t * HType.t 
      | Var of string
      | Lam of string * t
      | Ap of t * t 
      | NumLit of int
      | Plus of t * t
      | EmptyHole 
      | NonEmptyHole of t
  end

  module ZType = struct
    type t = 
      | FocusedT of HType.t
      | FirstArrow of t * HType.t
      | SecondArrow of HType.t * t 
  end

  module ZExp = struct
    type t = 
      | FocusedE of HExp.t
      | LeftAsc of t * HType.t
      | RightAsc of HType.t * t 
      | LamZ of string * t
      | LeftAp of t * HExp.t
      | RightAp of HExp.t * t 
      | LeftPlus of t * HExp.t
      | RightPlus of HExp.t * t
      | NonEmptyHoleZ of t
  end


  open HExp
  open ZExp
  (* let empty = (HType.Arrow ((HType.Hole),(HType.Arrow ((HType.Num 1),(HType.Num 2)))))    *)
  (* let empty = Lam ((Var "x"),InProgressHole (Plus (NumLit 1, NumLit 3))) *)
  let empty = RightPlus ((NumLit 1), (FocusedE (NumLit 2)))
end

type rs = Model.ZExp.t React.signal
type rf = ?step:React.step -> Model.ZExp.t -> unit
type rp = rs * rf

module Action = struct
  type direction =  
      FirstChild 
    | Parent 
    | NextSib 
    | PrevSib

  type shape = 
    | SArrow
    | SNum
    | SAsc
    | SVar of string
    | SLam of string
    | SAp 
    | SArg
    | SNumlit of int
    | SPlus

  type t =
      Move of direction
    | Del 
    | Construct of shape
    | Finish

end

module Controller = struct

  open Action

  let update a ((rs, rf) : rp) =
    let m = React.S.value rs in 
    let m = 
      match a with 
      | Del -> (Model.ZExp.FocusedE (Model.HExp.Var "b"))
      | Finish -> (Model.ZExp.FocusedE (Model.HExp.Var "b"))
      | _ -> (Model.ZExp.FocusedE (Model.HExp.Var "c"))
    in
    rf m

end

module View = struct

  open Action
  open Tyxml_js
  open Model.HType
  open Model.HExp
  open Model.ZExp
  open Model.ZType

  let rec stringFromHType (htype : Model.HType.t ) : string = match htype with
    | Num n -> string_of_int n
    | Arrow (fst,snd) -> "(" ^ stringFromHType (fst) ^ "->" ^ stringFromHType (snd) ^ ")"
    | Hole -> "H" 

  let rec stringFromHExp (hexp : Model.HExp.t ) : string = match hexp with
    | Asc (hexp,htype) -> (stringFromHExp hexp) ^ ":" ^ (stringFromHType htype)
    | Var str -> str
    | Lam (var,exp) -> "λ" ^  var ^ "." ^ (stringFromHExp exp)
    | Ap (e1, e2) -> (stringFromHExp e1) ^ "(" ^ (stringFromHExp e2) ^ ")"
    | NumLit num -> string_of_int num
    | Plus (n1,n2) -> (stringFromHExp n1) ^"+"^ (stringFromHExp n2)
    | EmptyHole ->  "{}" 
    | NonEmptyHole hc -> "{" ^ (stringFromHExp hc) ^ "}"

  let rec stringFromZType (ztype : Model.ZType.t ) : string = match ztype with
    | FocusedT htype -> ">" ^ stringFromHType htype ^ "<"
    | FirstArrow  (ztype, htype) -> stringFromZType ztype  ^ "->" ^ stringFromHType htype
    | SecondArrow (htype, ztype) -> stringFromHType htype ^ "->" ^ stringFromZType ztype

  let rec stringFromZExp (zexp : Model.ZExp.t ) : string = match zexp with
    | FocusedE hexp -> ">" ^ stringFromHExp hexp ^ "<"
    | LeftAsc (e, asc) -> stringFromZExp e ^ stringFromHType asc 
    | RightAsc (e, asc) -> stringFromHType e ^ stringFromZExp asc
    | LamZ (var,exp) -> stringFromZExp exp
    | LeftAp (e1,e2) -> stringFromZExp e1 ^ stringFromHExp e2
    | RightAp (e1,e2) -> stringFromHExp e1 ^ stringFromZExp e2
    | LeftPlus (num1,num2) -> stringFromZExp num1 ^ "+" ^ stringFromHExp num2
    | RightPlus (num1,num2) -> stringFromHExp num1  ^ "+" ^ stringFromZExp num2
    | NonEmptyHoleZ e -> "{" ^ stringFromZExp e ^ "}"

  let viewNum (rs, rf) =
    let num = React.S.value rs in
    Html5.(p [pcdata (stringFromZExp num)]) 

  let viewActions (rs, rf) =
    let onClick evt =
      Controller.update (Del) (rs, rf) ;
      true
    in
    (* Html5.(p [pcdata (stringFromZExp num)])  *)
    Html5.(div ~a:[a_onclick onClick] [pcdata "del"] )



  let view (rs, rf) =
    let num = viewNum (rs, rf) in 
    let actions = viewActions (rs, rf) in 
    Html5.(
      div [
        div ~a:[a_class ["comments"]] [
          p [
            pcdata "HZ model"
          ] ;
        ] ;
        div ~a:[a_class ["Model"]]  [ num ] ;
        div ~a:[a_class ["Actions"]]  [ actions ]
      ]
    ) 

end

let main _ =
  let doc = Dom_html.document in
  let parent =
    Js.Opt.get (doc##getElementById(Js.string "container"))
      (fun () -> assert false)
  in
  let m = Model.empty in
  let rp = React.S.create m in
  Dom.appendChild parent (Tyxml_js.To_dom.of_div (View.view rp)) ;
  Lwt.return ()

let _ = Lwt_js_events.onload () >>= main
