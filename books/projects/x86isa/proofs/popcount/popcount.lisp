; X86ISA Library

; Note: The license below is based on the template at:
; http://opensource.org/licenses/BSD-3-Clause

; Copyright (C) 2015, Regents of the University of Texas
; All rights reserved.

; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are
; met:

; o Redistributions of source code must retain the above copyright
;   notice, this list of conditions and the following disclaimer.

; o Redistributions in binary form must reproduce the above copyright
;   notice, this list of conditions and the following disclaimer in the
;   documentation and/or other materials provided with the distribution.

; o Neither the name of the copyright holders nor the names of its
;   contributors may be used to endorse or promote products derived
;   from this software without specific prior written permission.

; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
; HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

; Original Author(s):
; Shilpi Goel         <shigoel@cs.utexas.edu>

(in-package "X86ISA")

;; Tweaked by Eric Smith to include official top-level book for app-view proofs:
(include-book "app-view/top" :dir :proof-utils :ttags :all)
(include-book "../../tools/execution/init-state" :ttags :all)
(include-book "centaur/gl/gl" :dir :system)
(include-book "std/testing/must-fail" :dir :system)

(local (include-book "centaur/bitops/ihs-extensions" :dir :system))

(set-irrelevant-formals-ok t)

;; ======================================================================

;; C program:
;; // gcc -g -O2 popcount-64.c -o popcount-64.o

;; #include <stdio.h>
;; #include <stdlib.h>

;; int popcount_32 (unsigned int v)
;; {
;;   v = v - ((v >> 1) & 0x55555555);
;;   v = (v & 0x33333333) + ((v >> 2) & 0x33333333);
;;   v = ((v + (v >> 4) & 0xF0F0F0F) * 0x1010101) >> 24;
;;   return(v);
;; }

;; int popcount_64 (long unsigned int v)
;; {
;;   long unsigned int v1, v2;
;;   // v1: lower 32 bits of v
;;   v1 = (v & 0xFFFFFFFF);
;;   // printf ("\n v1: %lu", v1);
;;   // v2: upper 32 bits of v
;;   v2 = (v >> 32);
;;   // printf ("\n v2: %lu", v2);
;;   return (popcount_32(v1) + popcount_32(v2));
;; }

;; int main (int argc, char *argv[], char *env[])
;; {
;;   long unsigned int v;
;;   printf ("\nEnter the value v: ");
;;   scanf  ("%lu", &v);
;;   printf ("\nPopcount of %lu is: %d\n", v, popcount_64(v));
;;   return 0;
;; }

(defconst *popcount-64*
  (list

   ;; Section: <popcount_32>:


   (cons #x400610 #x89) ;; mov %edi,%edx
   (cons #x400611 #xfa) ;;
   (cons #x400612 #xd1) ;; shr %edx
   (cons #x400613 #xea) ;;
   (cons #x400614 #x81) ;; and $0x55555555,%edx
   (cons #x400615 #xe2) ;;
   (cons #x400616 #x55) ;;
   (cons #x400617 #x55) ;;
   (cons #x400618 #x55) ;;
   (cons #x400619 #x55) ;;
   (cons #x40061a #x29) ;; sub %edx,%edi
   (cons #x40061b #xd7) ;;
   (cons #x40061c #x89) ;; mov %edi,%eax
   (cons #x40061d #xf8) ;;
   (cons #x40061e #xc1) ;; shr $0x2,%edi
   (cons #x40061f #xef) ;;
   (cons #x400620 #x02) ;;
   (cons #x400621 #x25) ;; and $0x33333333,%eax
   (cons #x400622 #x33) ;;
   (cons #x400623 #x33) ;;
   (cons #x400624 #x33) ;;
   (cons #x400625 #x33) ;;
   (cons #x400626 #x81) ;; and $0x33333333,%edi
   (cons #x400627 #xe7) ;;
   (cons #x400628 #x33) ;;
   (cons #x400629 #x33) ;;
   (cons #x40062a #x33) ;;
   (cons #x40062b #x33) ;;
   (cons #x40062c #x01) ;; add %eax,%edi
   (cons #x40062d #xc7) ;;
   (cons #x40062e #x89) ;; mov %edi,%eax
   (cons #x40062f #xf8) ;;
   (cons #x400630 #xc1) ;; shr $0x4,%eax
   (cons #x400631 #xe8) ;;
   (cons #x400632 #x04) ;;
   (cons #x400633 #x01) ;; add %edi,%eax
   (cons #x400634 #xf8) ;;
   (cons #x400635 #x25) ;; and $0xf0f0f0f,%eax
   (cons #x400636 #x0f) ;;
   (cons #x400637 #x0f) ;;
   (cons #x400638 #x0f) ;;
   (cons #x400639 #x0f) ;;
   (cons #x40063a #x69) ;; imul $0x1010101,%eax,%eax
   (cons #x40063b #xc0) ;;
   (cons #x40063c #x01) ;;
   (cons #x40063d #x01) ;;
   (cons #x40063e #x01) ;;
   (cons #x40063f #x01) ;;
   (cons #x400640 #xc1) ;; shr $0x18,%eax
   (cons #x400641 #xe8) ;;
   (cons #x400642 #x18) ;;
   (cons #x400643 #xc3) ;; retq
   (cons #x400644 #x66) ;; data32 data32 nopw %cs:0x0(%rax,%rax,1)
   (cons #x400645 #x66) ;;
   (cons #x400646 #x66) ;;
   (cons #x400647 #x2e) ;;
   (cons #x400648 #x0f) ;;
   (cons #x400649 #x1f) ;;
   (cons #x40064a #x84) ;;
   (cons #x40064b #x00) ;;
   (cons #x40064c #x00) ;;
   (cons #x40064d #x00) ;;
   (cons #x40064e #x00) ;;
   (cons #x40064f #x00) ;;

   ;; Section: <popcount_64>:


   (cons #x400650 #x89) ;; mov %edi,%edx
   (cons #x400651 #xfa) ;;
   (cons #x400652 #x89) ;; mov %edx,%ecx
   (cons #x400653 #xd1) ;;
   (cons #x400654 #xd1) ;; shr %ecx
   (cons #x400655 #xe9) ;;
   (cons #x400656 #x81) ;; and $0x55555555,%ecx
   (cons #x400657 #xe1) ;;
   (cons #x400658 #x55) ;;
   (cons #x400659 #x55) ;;
   (cons #x40065a #x55) ;;
   (cons #x40065b #x55) ;;
   (cons #x40065c #x29) ;; sub %ecx,%edx
   (cons #x40065d #xca) ;;
   (cons #x40065e #x89) ;; mov %edx,%eax
   (cons #x40065f #xd0) ;;
   (cons #x400660 #xc1) ;; shr $0x2,%edx
   (cons #x400661 #xea) ;;
   (cons #x400662 #x02) ;;
   (cons #x400663 #x25) ;; and $0x33333333,%eax
   (cons #x400664 #x33) ;;
   (cons #x400665 #x33) ;;
   (cons #x400666 #x33) ;;
   (cons #x400667 #x33) ;;
   (cons #x400668 #x81) ;; and $0x33333333,%edx
   (cons #x400669 #xe2) ;;
   (cons #x40066a #x33) ;;
   (cons #x40066b #x33) ;;
   (cons #x40066c #x33) ;;
   (cons #x40066d #x33) ;;
   (cons #x40066e #x01) ;; add %eax,%edx
   (cons #x40066f #xc2) ;;
   (cons #x400670 #x89) ;; mov %edx,%eax
   (cons #x400671 #xd0) ;;
   (cons #x400672 #xc1) ;; shr $0x4,%eax
   (cons #x400673 #xe8) ;;
   (cons #x400674 #x04) ;;
   (cons #x400675 #x01) ;; add %eax,%edx
   (cons #x400676 #xc2) ;;
   (cons #x400677 #x48) ;; mov %rdi,%rax
   (cons #x400678 #x89) ;;
   (cons #x400679 #xf8) ;;
   (cons #x40067a #x48) ;; shr $0x20,%rax
   (cons #x40067b #xc1) ;;
   (cons #x40067c #xe8) ;;
   (cons #x40067d #x20) ;;
   (cons #x40067e #x81) ;; and $0xf0f0f0f,%edx
   (cons #x40067f #xe2) ;;
   (cons #x400680 #x0f) ;;
   (cons #x400681 #x0f) ;;
   (cons #x400682 #x0f) ;;
   (cons #x400683 #x0f) ;;
   (cons #x400684 #x89) ;; mov %eax,%ecx
   (cons #x400685 #xc1) ;;
   (cons #x400686 #xd1) ;; shr %ecx
   (cons #x400687 #xe9) ;;
   (cons #x400688 #x81) ;; and $0x55555555,%ecx
   (cons #x400689 #xe1) ;;
   (cons #x40068a #x55) ;;
   (cons #x40068b #x55) ;;
   (cons #x40068c #x55) ;;
   (cons #x40068d #x55) ;;
   (cons #x40068e #x29) ;; sub %ecx,%eax
   (cons #x40068f #xc8) ;;
   (cons #x400690 #x89) ;; mov %eax,%ecx
   (cons #x400691 #xc1) ;;
   (cons #x400692 #xc1) ;; shr $0x2,%eax
   (cons #x400693 #xe8) ;;
   (cons #x400694 #x02) ;;
   (cons #x400695 #x81) ;; and $0x33333333,%ecx
   (cons #x400696 #xe1) ;;
   (cons #x400697 #x33) ;;
   (cons #x400698 #x33) ;;
   (cons #x400699 #x33) ;;
   (cons #x40069a #x33) ;;
   (cons #x40069b #x25) ;; and $0x33333333,%eax
   (cons #x40069c #x33) ;;
   (cons #x40069d #x33) ;;
   (cons #x40069e #x33) ;;
   (cons #x40069f #x33) ;;
   (cons #x4006a0 #x01) ;; add %ecx,%eax
   (cons #x4006a1 #xc8) ;;
   (cons #x4006a2 #x89) ;; mov %eax,%ecx
   (cons #x4006a3 #xc1) ;;
   (cons #x4006a4 #xc1) ;; shr $0x4,%ecx
   (cons #x4006a5 #xe9) ;;
   (cons #x4006a6 #x04) ;;
   (cons #x4006a7 #x01) ;; add %ecx,%eax
   (cons #x4006a8 #xc8) ;;
   (cons #x4006a9 #x25) ;; and $0xf0f0f0f,%eax
   (cons #x4006aa #x0f) ;;
   (cons #x4006ab #x0f) ;;
   (cons #x4006ac #x0f) ;;
   (cons #x4006ad #x0f) ;;
   (cons #x4006ae #x69) ;; imul $0x1010101,%edx,%edx
   (cons #x4006af #xd2) ;;
   (cons #x4006b0 #x01) ;;
   (cons #x4006b1 #x01) ;;
   (cons #x4006b2 #x01) ;;
   (cons #x4006b3 #x01) ;;
   (cons #x4006b4 #x69) ;; imul $0x1010101,%eax,%eax
   (cons #x4006b5 #xc0) ;;
   (cons #x4006b6 #x01) ;;
   (cons #x4006b7 #x01) ;;
   (cons #x4006b8 #x01) ;;
   (cons #x4006b9 #x01) ;;
   (cons #x4006ba #xc1) ;; shr $0x18,%edx
   (cons #x4006bb #xea) ;;
   (cons #x4006bc #x18) ;;
   (cons #x4006bd #xc1) ;; shr $0x18,%eax
   (cons #x4006be #xe8) ;;
   (cons #x4006bf #x18) ;;
   (cons #x4006c0 #x01) ;; add %edx,%eax
   (cons #x4006c1 #xd0) ;;
   (cons #x4006c2 #xc3) ;; retq
   (cons #x4006c3 #x66) ;; nopw %cs:0x0(%rax,%rax,1)
   (cons #x4006c4 #x2e) ;;
   (cons #x4006c5 #x0f) ;;
   (cons #x4006c6 #x1f) ;;
   (cons #x4006c7 #x84) ;;
   (cons #x4006c8 #x00) ;;
   (cons #x4006c9 #x00) ;;
   (cons #x4006ca #x00) ;;
   (cons #x4006cb #x00) ;;
   (cons #x4006cc #x00) ;;
   (cons #x4006cd #x0f) ;; nopl (%rax)
   (cons #x4006ce #x1f) ;;
   (cons #x4006cf #x00) ;;

   ))

;; We could not use GL to prove such theorems on the earlier version
;; of our X86 model. GL needed to create large linear lists
;; (corresponding to the logical representation of our X86 state) in
;; order to symbolically execute functions that take the state as an
;; input. These lists were so large that creating them resulted in
;; unavoidable stack overflows.

;; However, on our current model with abstract stobjs, a sparse
;; logical representation of state makes symbolic execution by GL
;; possible.

;; We use GL term-level reasoning below to make it faster to reason
;; about reads/writes to/from the x86 state.  Another benefit is that
;; this way, the code proofs will work irrespective of the
;; representation of the x86 state as well as the definitions of the
;; universal accessor/updater function, as long as these rules about
;; xr/xw are true and made available to GL.

(gl::gl-set-uninterpreted xr)
(gl::gl-set-uninterpreted xw)
(gl::gl-set-uninterpreted create-x86)

(gl::add-gl-rewrite xr-of-xw-intra-field)
(gl::add-gl-rewrite xr-of-xw-inter-field)
(gl::add-gl-rewrite xw-of-xr)
(gl::add-gl-rewrite xw-xw-shadow-writes)
;; (gl::add-gl-rewrite xw-xw-intra-field-arrange-writes)
;; (gl::add-gl-rewrite xw-xw-inter-field-arrange-writes)
(gl::add-gl-rewrite x86p-xw)

(gl::def-gl-rewrite xr-of-create-x86
  (equal (xr fld index (create-x86))
         (x86-elem-default fld)))

(gl::def-gl-branch-merge merge-conditional-write
  (equal (if test (xw fld index val x86) x86)
         (xw fld index (if test val (xr fld index x86)) x86)))

(gl::gl-set-uninterpreted create-undef)

(gl::def-gl-rewrite split-on-logapp-of-create-undef
  ;; From Sol Swords.
  (equal (logapp 1 (create-undef x) 0)
         (let ((undef (create-undef x)))
           (if (gl::gl-hide (logbitp 0 undef))
               1
             0))))

(gl::def-gl-rewrite integerp-of-create-undef
  (equal (integerp (create-undef n)) t))

(local
 (def-gl-thm term-level-reasoning-test ;; ok after adding gl-rewrites; not okay before that
   :hyp (unsigned-byte-p 32 n)
   :concl (b* ((x86 (XW :RGF *RDI* (LOGHEAD 32 N)
                        (XW :RIP nil 4195856
                            (XW :SEG-HIDDEN-ATTR 1 512 (create-x86))))))
            (equal (rgfi *RDI* x86) n))
   :g-bindings
   `((n    (:g-number ,(increasing-list 0 1 33))))
   :n-counterexamples 0
   :rule-classes nil))

(def-gl-thm x86-popcount-32-correct
  :hyp (and (natp n)
            (< n (expt 2 32)))
  :concl (b* ((start-address #x400610)
              (halt-address #x400643)
              (x86 (!app-view t (create-x86)))
              ((mv flg x86)
               (init-x86-state-64
                nil start-address
                nil nil nil nil nil nil nil 0
                *popcount-64*
                x86))
              (x86 (wr32 *rdi* n x86))
              (count 300)
              (x86 (x86-run-halt halt-address count x86)))
           (and (equal (rgfi *rax* x86) (logcount n))
                (equal flg nil)
                (equal (rip x86) halt-address)
                (equal (ms x86) `((x86-fetch-decode-execute-halt
                                   :rip ,halt-address)))))
  :g-bindings
  `((n    (:g-number ,(increasing-list 0 1 33))))
  :n-counterexamples 0
  :abort-indeterminate t
  :exec-ctrex nil
  :rule-classes nil)

(def-gl-thm x86-popcount-correct
  :hyp (and (natp n)
            (< n (expt 2 64)))
  :concl (b* ((start-address #x400650)
              (halt-address #x4006c2)
              (x86 (!app-view t (create-x86)))
              ((mv flg x86)
               (init-x86-state-64
                nil start-address
                nil nil nil nil nil nil nil 0
                *popcount-64*
                x86))
              (x86 ;; (!rgfi *rdi* n x86)
               ;; Shilpi: It's important to use wr64 instead of !rgfi
               ;; because wr64 converts unsigned numbers to signed
               ;; ones, which is the representation of GPRs in the x86
               ;; state.
               (wr64 *rdi* n x86))
              (count 300)
              (x86 (x86-run-halt halt-address count x86)))
           (and (equal (rgfi *rax* x86)
                       (logcount n))
                (equal flg nil)
                (equal (rip x86) halt-address)
                (equal (ms x86) `((x86-fetch-decode-execute-halt
                                   :rip ,halt-address)))))
  :g-bindings
  `((n   (:g-number ,(increasing-list 0 1 65))))
  :n-counterexamples 1
  :abort-indeterminate t
  :exec-ctrex nil
  :rule-classes nil)

;; ======================================================================

;; Now, an experiment involving a buggy popcount implementation:

;; Final SHR replaced with a NOP instruction.
(defconst *popcount-32-buggy*
  (list

   ;; Section: <popcount_32>:


   (cons #x400610 #x89) ;; mov %edi,%edx
   (cons #x400611 #xfa) ;;
   (cons #x400612 #xd1) ;; shr %edx
   (cons #x400613 #xea) ;;
   (cons #x400614 #x81) ;; and $0x55555555,%edx
   (cons #x400615 #xe2) ;;
   (cons #x400616 #x55) ;;
   (cons #x400617 #x55) ;;
   (cons #x400618 #x55) ;;
   (cons #x400619 #x55) ;;
   (cons #x40061a #x29) ;; sub %edx,%edi
   (cons #x40061b #xd7) ;;
   (cons #x40061c #x89) ;; mov %edi,%eax
   (cons #x40061d #xf8) ;;
   (cons #x40061e #xc1) ;; shr $0x2,%edi
   (cons #x40061f #xef) ;;
   (cons #x400620 #x02) ;;
   (cons #x400621 #x25) ;; and $0x33333333,%eax
   (cons #x400622 #x33) ;;
   (cons #x400623 #x33) ;;
   (cons #x400624 #x33) ;;
   (cons #x400625 #x33) ;;
   (cons #x400626 #x81) ;; and $0x33333333,%edi
   (cons #x400627 #xe7) ;;
   (cons #x400628 #x33) ;;
   (cons #x400629 #x33) ;;
   (cons #x40062a #x33) ;;
   (cons #x40062b #x33) ;;
   (cons #x40062c #x01) ;; add %eax,%edi
   (cons #x40062d #xc7) ;;
   (cons #x40062e #x89) ;; mov %edi,%eax
   (cons #x40062f #xf8) ;;
   (cons #x400630 #xc1) ;; shr $0x4,%eax
   (cons #x400631 #xe8) ;;
   (cons #x400632 #x04) ;;
   (cons #x400633 #x01) ;; add %edi,%eax
   (cons #x400634 #xf8) ;;
   (cons #x400635 #x25) ;; and $0xf0f0f0f,%eax
   (cons #x400636 #x0f) ;;
   (cons #x400637 #x0f) ;;
   (cons #x400638 #x0f) ;;
   (cons #x400639 #x0f) ;;
   (cons #x40063a #x69) ;; imul $0x1010101,%eax,%eax
   (cons #x40063b #xc0) ;;
   (cons #x40063c #x01) ;;
   (cons #x40063d #x01) ;;
   (cons #x40063e #x01) ;;
   (cons #x40063f #x01) ;;

   ;; (cons #x400640 #xc1) ;; shr $0x18,%eax
   ;; (cons #x400641 #xe8) ;;
   ;; (cons #x400642 #x18) ;;
   (cons #x400640 #x0f)    ;; nopl (%rax)
   (cons #x400641 #x1f)    ;;
   (cons #x400642 #x00)    ;;

   (cons #x400643 #xc3) ;; retq
   (cons #x400644 #x66) ;; data32 data32 nopw %cs:0x0(%rax,%rax,1)
   (cons #x400645 #x66) ;;
   (cons #x400646 #x66) ;;
   (cons #x400647 #x2e) ;;
   (cons #x400648 #x0f) ;;
   (cons #x400649 #x1f) ;;
   (cons #x40064a #x84) ;;
   (cons #x40064b #x00) ;;
   (cons #x40064c #x00) ;;
   (cons #x40064d #x00) ;;
   (cons #x40064e #x00) ;;
   (cons #x40064f #x00) ;;

   ))

;; FAILS!
(acl2::must-fail
 (def-gl-thm x86-popcount-32-buggy
   :hyp (and (natp n)
             (< n (expt 2 32)))
   :concl (b* ((start-address #x400610)
               (halt-address #x400643)
               (x86 (!app-view t (create-x86)))
               ((mv flg x86)
                (init-x86-state-64
                 nil start-address
                 nil nil nil nil nil nil nil 0
                 *popcount-32-buggy*
                 x86))
               (x86 (wr32 *rdi* n x86))
               (count 300)
               (x86 (x86-run-halt halt-address count x86)))
            (and (equal (rgfi *rax* x86)
                        (logcount n))
                 (equal flg nil)
                 (equal (rip x86) halt-address)
                 (equal (ms x86) `((x86-fetch-decode-execute-halt
                                    :rip ,halt-address)))))
   :g-bindings
   `((n    (:g-number ,(increasing-list 0 1 33))))
   :n-counterexamples 3
   :abort-indeterminate t
   :exec-ctrex nil))

#||

(b* ((start-address #x400610)
     (halt-address #x400643)
     (x86 (!app-view t x86))
     ((mv ?flg x86)
      (init-x86-state-64
       nil start-address
       nil nil nil nil nil 0
       *popcount-32-buggy*
       x86))
     (x86 (wr32 *rdi* #x80000000  x86))
     (count 300)
     (x86 (x86-run-halt halt-address count x86)))
  x86)
(rgfi *rax* x86)

(b* ((start-address #x400610)
     (halt-address #x400643)
     (x86 (!app-view t x86))
     ((mv ?flg x86)
      (init-x86-state-64
       nil start-address
       nil nil nil nil nil 0
       *popcount-32-buggy*
       x86))
     (x86 (wr32 *rdi* #xFFFFFFFF  x86))
     (count 300)
     (x86 (x86-run-halt halt-address count x86)))
  x86)
(rgfi *rax* x86)

||#

;; Succeeds!
(def-gl-thm x86-popcount-32-buggy-spec
  :hyp (and (natp n)
            (< n (expt 2 32)))
  :concl (b* ((start-address #x400610)
              (halt-address #x400643)
              (x86 (!app-view t (create-x86)))
              ((mv flg x86)
               (init-x86-state-64
                nil start-address
                nil nil nil nil nil nil nil 0
                *popcount-32-buggy*
                x86))
              (x86 (wr32 *rdi* n x86))
              (count 300)
              (x86 (x86-run-halt halt-address count x86)))
           (and (equal (ash (rgfi *rax* x86) -24)
                       (logcount n))
                (equal flg nil)
                (equal (rip x86) halt-address)
                (equal (ms x86) `((x86-fetch-decode-execute-halt
                                   :rip ,halt-address)))))
  :g-bindings
  `((n    (:g-number ,(increasing-list 0 1 33))))
  :n-counterexamples 3
  :abort-indeterminate t
  :exec-ctrex nil)

;; ======================================================================
