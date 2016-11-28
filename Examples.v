Require Import HoTT.
Require Import Auxiliary.
Require Import RawSyntax.

Section Types_as_shapes.
  Definition Type_Shape : Shape_System.
  Proof.
    refine {|
        Shape := Type ;
        positions := (fun A => A) ;
        shape_empty := Empty ;
        shape_coprod := sum ;
        shape_extend := option
      |}.
    - constructor.
      intros P x; elim x.
    - intros A B.
      simple refine {|
          coprod_inj1 := @inl A B ;
          coprod_inj2 := @inr A B ;
        |}.
      + intros P f g x.
        destruct x as [a|b].
        * apply f.
        * apply g.
      + reflexivity.
      + reflexivity.
    - intro A.
      simple refine {|
          plusone_top := None ;
          plusone_next := @Some A
        |}.
      * { intros P e f [x|].
          - now apply f.
          - exact e. }
      * reflexivity.
      * reflexivity.
  Defined.

End Types_as_shapes.

Section Free_shapes.

  Inductive f_cxt : Type :=
  | f_empty : f_cxt
  | f_coprod : f_cxt -> f_cxt -> f_cxt
  | f_extend : f_cxt -> f_cxt.
  
  Fixpoint f_positions (c : f_cxt) : Type :=
    match c with
    | f_empty => Empty
    | f_coprod c d => sum (f_positions c) (f_positions d)
    | f_extend c => option (f_positions c)
    end.

  Definition Free_Shape : Shape_System.
  Proof.
    refine {|
        Shape := f_cxt ;
        positions := f_positions ;
        shape_empty := f_empty ;
        shape_coprod := f_coprod ;
        shape_extend := f_extend
      |}.
    - constructor.
      intros P x; elim x.
    - intros c d.
      simple refine {|
          coprod_inj1 := @inl (f_positions c) (f_positions d) ;
          coprod_inj2 := @inr (f_positions c) (f_positions d) ;
        |}.
      + intros P f g x.
        destruct x as [a|b].
        * apply f.
        * apply g.
      + reflexivity.
      + reflexivity.
    - intro c.
      simple refine {|
          plusone_top := None ;
          plusone_next := @Some (f_positions c)
        |}.
      * { intros P e f [x|].
          - now apply f.
          - exact e. }
      * reflexivity.
      * reflexivity.
  Defined.

End Free_shapes.

Section DeBruijn.

  Inductive DB_positions : nat -> Type :=
    | zero_db : forall {n}, DB_positions (S n)
    | succ_db : forall {n}, DB_positions n -> DB_positions (S n).

  Fixpoint DB_inl (n m : nat) (x : DB_positions n) : DB_positions (n + m).
  Proof.
    destruct x.
    - exact zero_db.
    - apply succ_db, DB_inl; exact x.
  Defined.

  Fixpoint DB_inr (n m : nat) (x : DB_positions m) : DB_positions (n + m).
  Proof.
    destruct n.
    - exact x.
    - apply succ_db, DB_inr; exact x. (* XXX Here "now" fails with f_equal. *)
  Defined.
  
  Lemma plus_is_coprod (n m : nat) :
    is_coprod (DB_positions (n + m))
              (DB_positions n)
              (DB_positions m).
  Proof.
    simple refine
      {| 
        coprod_inj1 := DB_inl n m;
        coprod_inj2 := DB_inr n m
      |}.
    (* coprod_rect *)
    - intros P L R x.
      pose (Q := fun k x => forall (p : k = (n + m)%nat),
                     P (transport DB_positions p x)).
      (* use Q instead of P *)
      admit.
  Admitted.

  (* Defined. *)

  Definition DeBruijn : Shape_System.
  Proof.
    refine {| Shape := nat ;
              positions := DB_positions ;
              shape_empty := 0 ;
              shape_coprod := (fun n m => (n + m)%nat) ;
              shape_extend := S
           |}.
    (* shape_is_empty *)
    - constructor.
      intros P x.
      admit. (* P zero_db is empty *)
    (* shape_is_coprod *)
    - apply plus_is_coprod.
    (* shape_is_plusone *)
    - intro c.
      admit.
  Admitted.

End DeBruijn.

(* TODO: variables as strings, or as natural numbers *)

(* TODO: Should also generalise to any constructively infinite type. *)