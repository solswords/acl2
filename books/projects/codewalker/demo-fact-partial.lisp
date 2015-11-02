; Copyright (C) 2015, Regents of the University of Texas
; License: A 3-clause BSD license.  See the LICENSE file distributed with ACL2.

; This file was created by Matt Kaufmann, by adapting demo-fact.lisp, which in
; turn is adapted from J Moore's file, basic-demo.lsp.

;;; This is a first cut at using defpm to do partial correctness proofs with
;;; Codewalker, and even to derive from them (deferred) proofs of total
;;; correctness.  Perhaps it can serve as a guide for modifying Codewalker to
;;; support this approach directly.

;;; We start with an existing demo and then unroll back through the
;;; def-semantics (and def-projection) forms.

(in-package "M1")

;;; I imagine Codewalker as including defpm:

(include-book "misc/defpm" :dir :system)

;;; We start by including the first part of demo-fact.lisp.

(include-book "demo-fact-preamble")
(set-verify-guards-eagerness 0) ; local to the book above

;;; It could be good for def-semantics to be revised, so that the events below
;;; are generated by the following form (which is unchanged from the original).

; (def-semantics
;   :init-pc 0
;   :focus-regionp nil
;   :root-name nil
;   :hyps+ ((program1p s))
;   :annotations nil
;   )

;;; For each event below, if it corresponds to one formerly generated by the
;;; above def-semantics call then we precede it by a comment explaining how it
;;; has changed.  Otherwise, the comment above it explains how the form might
;;; be generated automatically by Codewalker, such as for the first form below.

;;; Test-4: to be newly generated.  In general, the form of the body below
;;; is:
;;; (or (not (and <hyps+> <generated_invariant>))
;;;     <test_from_original_body_of_clk-4>)

(defun-nx test-4 (s)
  (declare (xargs :stobjs (s)))
  (or (not (and (and (hyps s)
                     (program1p s))
                (equal (nth 3 (rd :locals s)) 1)))
      (equal (nth 0 (rd :locals s)) 0)))

;;; Step-4: to be newly generated.  In general, the body below is just the
;;; argument of the recursive call in the definition of clk-4.  So far I've
;;; only contemplated carefully the case that clk-4 has a single recursive
;;; call.  More generally, we might fold the test and recursive calls into a
;;; single test and recursive call, much as defp does when taking advantage of
;;; defpun.  (Note by the way that since s is the only parameter, there is no
;;; need to consider the feature of defpm that supports the non-unary case by
;;; allowing one call per argument.)

(defun-nx step-4 (s)
  (wr :pc
      4
      (wr :locals
          (update-nth 0
                      (+ (nth 0 (rd :locals s))
                         (- (nth 3 (rd :locals s))))
                      (update-nth 1
                                  (* (nth 0 (rd :locals s))
                                     (nth 1 (rd :locals s)))
                                  (rd :locals s)))
          s)))

;;; To be newly generated: Codewalker would generate the following form to
;;; introduce measure-4, terminates-4, and theory-4 automatically, perhaps when
;;; def-semantics is supplied with :MEASURE :PARTIAL, or maybe :PARTIAL T.  The
;;; suffix "-4" comes from the PC.  Of course, if the def-semantics form
;;; specifies a :ROOT-NAME prefix, it would be used for all five of these
;;; function names.

(acl2::defpm test-4 step-4 measure-4 terminates-4 theory-4)

;;; Clk-4: modified as shown below.  Old code to be deleted is commented out;
;;; new code is in upper case.  I'd expect these modifications to be made
;;; automatically by Codewalker when def-semantics is supplied with :MEASURE
;;; :PARTIAL, or maybe :PARTIAL T.

(defun clk-4 (s)
  (declare (xargs :non-executable t :mode :logic))
  (declare (xargs
            :measure
;           (acl2::defunm-marker (acl2-count (nth 0 (rd :locals s))))
            (MEASURE-4 S)
            :HINTS (("GOAL"
                     :USE ((:INSTANCE MEASURE-4-DECREASES
                                      (ACL2::X S))
                           (:INSTANCE MEASURE-4-TYPE
                                      (ACL2::X S)))
                     :IN-THEORY
                     (UNION-THEORIES '(TEST-4 STEP-4)
                                     (THEORY 'GROUND-ZERO))))
            :well-founded-relation o<))
  (declare (xargs :stobjs (s)))
  (prog2$
   (acl2::throw-nonexec-error 'clk-4 (list s))
   (if (and (and (hyps s)
                 (program1p s))
            (equal (nth 3 (rd :locals s)) 1)
            (TERMINATES-4 S))
       (if (equal (nth 0 (rd :locals s)) 0)
           3
         (binary-clk+
          11
          (clk-4
           (wr :pc
               4
               (wr :locals
                   (update-nth 0
                               (+ (nth 0 (rd :locals s))
                                  (- (nth 3 (rd :locals s))))
                               (update-nth 1
                                           (* (nth 0 (rd :locals s))
                                              (nth 1 (rd :locals s)))
                                           (rd :locals s)))
                   s)))))
     0)))

;;; The definition of clk-0 is unchanged.

(defun clk-0 (s)
  (declare (xargs :non-executable t :mode :logic))
  (declare (xargs :stobjs (s)))
  (prog2$
   (acl2::throw-nonexec-error 'clk-0 (list s))
   (if (and (hyps s)
            (program1p s))
       (binary-clk+
        4
        (clk-4 (wr :pc
                   4
                   (wr :locals
                       (update-nth 1 1 (update-nth 3 1 (rd :locals s)))
                       s))))
     0)))

;;; [Same comment as for Clk-4 above, except starts with "Sem-4":]
;;; Sem-4: modified as shown below.  Old code to be deleted is commented out;
;;; new code is in upper case.  I'd expect these modifications to be made
;;; automatically by Codewalker when def-semantics is supplied with :MEASURE
;;; :PARTIAL, or maybe :PARTIAL T.

(defun sem-4 (s)
  (declare (xargs :non-executable t :mode :logic))
  (declare (xargs
            :measure
;           (acl2::defunm-marker (acl2-count (nth 0 (rd :locals s))))
            (MEASURE-4 S)
            :HINTS (("GOAL"
                     :USE ((:INSTANCE MEASURE-4-DECREASES
                                      (ACL2::X S))
                           (:INSTANCE MEASURE-4-TYPE
                                      (ACL2::X S)))
                     :IN-THEORY
                     (UNION-THEORIES '(TEST-4 STEP-4)
                                     (THEORY 'GROUND-ZERO))))
            :well-founded-relation o<))
  (declare (xargs :stobjs (s)))
  (prog2$
   (acl2::throw-nonexec-error 'sem-4 (list s))
   (if (and (and (hyps s)
                 (program1p s))
            (equal (nth 3 (rd :locals s)) 1)
            (TERMINATES-4 S))
       (if (equal (nth 0 (rd :locals s)) 0)
           (wr :pc
               16
               (wr :stack
                   (push (nth 1 (rd :locals s))
                         (rd :stack s))
                   s))
         (sem-4 (wr :pc
                    4
                    (wr :locals
                        (update-nth 0
                                    (+ (nth 0 (rd :locals s))
                                       (- (nth 3 (rd :locals s))))
                                    (update-nth 1
                                                (* (nth 0 (rd :locals s))
                                                   (nth 1 (rd :locals s)))
                                                (rd :locals s)))
                        s))))
     s)))

;;; The definition of sem-0 is unchanged.

(defun sem-0 (s)
  (declare (xargs :non-executable t :mode :logic))
  (declare (xargs :stobjs (s)))
  (prog2$
   (acl2::throw-nonexec-error 'sem-0 (list s))
   (if (and (hyps s)
            (program1p s))
       (sem-4 (wr :pc
                  4
                  (wr :locals
                      (update-nth 1 1 (update-nth 3 1 (rd :locals s)))
                      s)))
     s)))

;;; The next four events are unchanged.

(defthm sem-4-correct
  (implies (and (hyps s)
                (program1p s)
                (equal (rd :pc s) 4))
           (equal (m1 s (clk-4 s)) (sem-4 s))))
(in-theory (disable clk-4))
(defthm sem-0-correct
        (implies (and (hyps s)
                      (program1p s)
                      (equal (rd :pc s) 0))
                 (equal (m1 s (clk-0 s)) (sem-0 s))))
(in-theory (disable clk-0))

;;; End of events for def-semantics.

;;; The following events should be generated by the following def-projection
;;; (which is unchanged from the original), after def-projection is revised.

; (def-projection
;   :new-fn FN1-LOOP
;   :projector (nth 1 (rd :locals s))
;   :old-fn SEM-4
;   :hyps+ ((program1p s))
;   )

;;; In each case we precede each event by a suitable comment, as we did for the
;;; def-semantics call, above.

;;; Test-fn1: to be newly generated.  In general, the form of the body below is
;;; just (or test1 test2), where test1 and test2 are the first two tests in the
;;; COND form generated for the body of the :NEW-FN supplied to def-projection.

(defun test-fn1-loop (r0 r1 r3)
  (or (or (not (integerp r3))
          (< r3 0)
          (not (integerp r0))
          (< r0 0)
          (not (integerp r1))
          (< r1 0))
      (or (not (equal r3 1)) (equal r0 0))))

;;; Step-fn1-loop-xxx: to be newly generated.  In general, the form of each of
;;; the three bodies below is just the appropriate argument of the recursive
;;; call in the definition of :NEW-FN.  For example, the first definition below
;;; is for r0, and which is in the first position among the formals, so the
;;; body is the first argument of the recursive call of fn1-loop, i.e., (+ -1
;;; r0).

(defun step-fn1-loop-r0 (r0 r1 r3)
  (declare (ignore r1 r3))
  (+ -1 r0))

(defun step-fn1-loop-r1 (r0 r1 r3)
  (declare (ignore r3))
  (* r0 r1))

(defun step-fn1-loop-r3 (r0 r1 r3)
  (declare (ignore r0 r1 r3))
  1)

;;; To be newly generated: Codewalker would generate the following form to
;;; introduce measure-fn1-loop, terminates-fn1-loop, and theory-fn1-loop
;;; automatically, perhaps when def-projection is supplied with :MEASURE
;;; :PARTIAL, or maybe :PARTIAL T.  The :formals below come from the formals
;;; deduced by Codewalker for fn1-loop.  (I'm guessing it can figure out the
;;; formals even before it has the :measure and other stuff generated by
;;; defpm.)

(acl2::defpm test-fn1-loop step-fn1-loop measure-fn1-loop terminates-fn1-loop
             theory-fn1-loop
             :formals (r0 r1 r3))

;;; Fn1-loop: modified as shown below.  Old code to be deleted is commented
;;; out; new code is in upper case.  I'd expect these modifications to be made
;;; automatically by Codewalker.

(defun fn1-loop (r0 r1 r3)
  (declare (xargs
            :measure
;           (acl2::defunm-marker (acl2-count r0))
            (MEASURE-FN1-LOOP R0 R1 R3)
            :HINTS (("GOAL"
                     :USE (MEASURE-FN1-LOOP-DECREASES MEASURE-FN1-LOOP-TYPE)
                     :IN-THEORY
                     (UNION-THEORIES '(TEST-FN1-LOOP
                                       STEP-FN1-LOOP-R0
                                       STEP-FN1-LOOP-R1
                                       STEP-FN1-LOOP-R3)
                                     (THEORY 'GROUND-ZERO))))
            :well-founded-relation o<))
  (cond ((NOT (TERMINATES-FN1-LOOP R0 R1 R3))
         0) ; value 0 here could, I believe, be anything
        ((or (not (integerp r3))
             (not (integerp r0))
             (not (integerp r1))
             (< r3 0)
             (< r1 0)
             (< r0 0))
         0)
        ((or (not (equal r3 1)) (equal r0 0))
         r1)
        (t (fn1-loop (+ -1 r0) (* r0 r1) 1))))

;;; Newly generated: Codewalker could presumably generate the following
;;; automatically, by simplifying to normal form the lemma generated by defpm
;;; that is named in the :USE hint below, namely terminates-fn1-loop-step,
;;; instantiated by binding formals to virtual formals.

(defthm terminates-fn1-loop-step-expanded
  (implies (and (syntaxp (and (equal r0 '(nth '0 (rd ':locals s)))
                              (equal r1 '(nth '1 (rd ':locals s)))
                              (equal r3 ''1)))
                (force (not (test-fn1-loop r0 r1 r3))))
           (equal (terminates-fn1-loop r0 r1 r3)
                  (terminates-fn1-loop (+ -1 r0)
                                       (* r0 r1)
                                       1)))
  :hints (("Goal"
           :in-theory (disable terminates-fn1-loop-step)
           :use terminates-fn1-loop-step)))

;;; Modified from generated lemma fn1-loop-correct: Codewalker could generate
;;; the following by modifying its currently-generated lemma f1-loop-correct as
;;; shown, where the new parts are in upper-case.  EXCEPT: we imagine a variant
;;; of hyps+ coming into play here, that is sufficient to reason about the
;;; program without proving termination.  We don't expect to be able to prove
;;; anything about this program when one of the locals is negative.

(defun-nx hyps++ (s)
  (nat-listp (rd :locals s)))

(defthm fn1-loop-correct-PARTIAL
  (implies (and (hyps s)
                (program1p s)
                (HYPS++ S) ; see comment above
                (TERMINATES-4 S)
                (TERMINATES-FN1-LOOP (NTH '0 (RD ':LOCALS S))
                                     (NTH '1 (RD ':LOCALS S))
                                     (NTH '3 (RD ':LOCALS S))))
           (equal (nth '1 (rd ':locals (sem-4 s)))
                  (fn1-loop (nth '0 (rd ':locals s))
                            (nth '1 (rd ':locals s))
                            (nth '3 (rd ':locals s)))))
  :hints (("Goal" :in-theory (e/d (terminates-4-step-commuted)
                                  (terminates-4-step))))
  :RULE-CLASSES NIL)

;;; Now we address termination, first for the recursive functions generated by
;;; def-semantics and then for the recursive function generated by
;;; def-projection.

;;; NEW: Now we prove away the terminates predicate from the defpm form
;;; generated by the def-semantics form.  The user might have to supply this
;;; form himself.  However, a nice interface from Codewalker might be provided
;;; in order to generate the next form.

(acl2::defthm-domain terminates-4-holds
                     (implies (hyps++ s) ; might in general be stronger
                              (terminates-4 s))
                     :test test-4
                     :step step-4
                     :measure (acl2-count (nth 0 (rd :locals s))))

;;; The following is only included here to record what was proved immediately
;;; above.  It can be omitted.

(encapsulate
 ()
 (set-enforce-redundancy t)
 (defthm terminates-4-holds
   (implies (hyps++ s)
            (terminates-4 s))))

;;; Turning now to the def-projection recursion....

;;; NEW: Now we prove that terminates-fn1-loop holds.  (That function was
;;; generated by the defpm form that was generated from the def-projection
;;; form.)  The user might have to supply this form himself.  However, a nice
;;; interface from Codewalker might be provided in order to generate it.

(acl2::defthm-domain terminates-fn1-loop-holds
                     (terminates-fn1-loop r0 r1 r3)
                     :test test-fn1-loop
                     :step step-fn1-loop
                     :measure (acl2-count r0))

;;; The following is only included here to record what was proved immediately
;;; above.  It can be omitted.

(encapsulate
 ()
 (set-enforce-redundancy t)
 (defthm terminates-fn1-loop-holds
   (terminates-fn1-loop r0 r1 r3)))

;;; The following lemma is unchanged what was generated by the original
;;; def-projection form (from demo-fact.lisp), except for the hints.

(defthm fn1-loop-correct
  (implies (and (hyps s)
                (program1p s)
                (hyps++ s))
           (equal (nth '1 (rd ':locals (sem-4 s)))
                  (fn1-loop (nth '0 (rd ':locals s))
                            (nth '1 (rd ':locals s))
                            (nth '3 (rd ':locals s)))))
  :HINTS (("Goal"
           :IN-THEORY (UNION-THEORIES '(TERMINATES-4-HOLDS
                                        TERMINATES-FN1-LOOP-HOLDS)
                                      (THEORY 'MINIMAL-THEORY))
           :USE FN1-LOOP-CORRECT-PARTIAL)))

;;; I'll note that we could make the following definition rule for fn1-loop
;;; that avoids the termination predicate.  But it's not necessary.

#|| Optional:
(defthm fn1-loop-def
  (equal (fn1-loop r0 r1 r3)
         (cond ((or (not (integerp r3))
                    (< r3 0)
                    (not (integerp r0))
                    (< r0 0)
                    (not (integerp r1))
                    (< r1 0))
                0)
               ((or (not (equal r3 1)) (equal r0 0))
                r1)
               (t (fn1-loop (+ -1 r0) (* r0 r1) 1))))
  :hints (("Goal" :in-theory (union-theories
                              '(fn1-loop terminates-fn1-loop-holds)
                              (theory 'minimal-theory))))
  :rule-classes :definition)
||#

;;; The rest of this file is taken directly, without modification except as
;;; indicated by upper-case code in fn1-loop-is-!-gen, from demo-fact.lisp.

; Now we project the R1 component of SEM-0 and name that fn fn1.
(def-projection
  :new-fn FN1
  :projector (nth 1 (rd :locals s))
  :old-fn SEM-0
  :hyps+ ((program1p s)
          (hyps++ s))
  )

#||
M1 !>(pe 'fn1)
          42:x(DEF-PROJECTION :NEW-FN FN1 ...)
              \
>L             (DEFUN FN1 (R0)
                      (IF (OR (NOT (INTEGERP R0)) (< R0 0))
                          0 (FN1-LOOP R0 1 1)))
M1 !>(pe 'fn1-correct)
          42:x(DEF-PROJECTION :NEW-FN FN1 ...)
              \
>              (DEFTHM FN1-CORRECT
                       (IMPLIES (AND (HYPS S) (PROGRAM1P S) (HYPS++ S))
                                (EQUAL (NTH '1 (RD ':LOCALS (SEM-0 S)))
                                       (FN1 (NTH '0 (RD ':LOCALS S))))))
M1 !>
||#

; We can prove that fn1 is factorial by the easy, conventional method:

(defun ! (n)
  (if (zp n)
      1
      (* n (! (- n 1)))))

(defthm fn1-loop-is-!-gen
  (implies (and (natp r0) (natp r1) (EQUAL R3 1))
           (equal (fn1-loop r0 r1 R3)
                  (* r1 (! r0))))
  :HINTS (("Goal" :INDUCT (FN1-LOOP R0 R1 R3))))

(defthm fn1-is-!
  (implies (natp r0)
           (equal (fn1 r0)
                  (! r0))))

; And because of all we know, we can immediately relate it to the
; result of running the code:

(defthm reg[1]-of-code-is-!
  (implies (and (hyps s)
                (program1p s)
                (hyps++ s)
                (equal (rd :pc s) 0))
           (equal (nth 1 (rd :locals (m1 s (clk-0 s))))
                  (! (nth 0 (rd :locals s))))))