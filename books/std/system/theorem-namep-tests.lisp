; Standard System Library
;
; Copyright (C) 2024 Kestrel Institute (http://www.kestrel.edu)
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Author: Alessandro Coglio (www.alessandrocoglio.info)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "ACL2")

(include-book "theorem-namep")

(include-book "std/testing/assert-bang" :dir :system)
(include-book "std/testing/must-succeed-star" :dir :system)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(assert! (theorem-namep 'car-cdr-elim (w state)))

(assert! (not (theorem-namep 'cons (w state))))

(assert! (not (theorem-namep 'aaaaaaaaa (w state))))

(must-succeed*
 (defthm th (acl2-numberp (+ x y)))
 (assert! (theorem-namep 'th (w state))))

(assert! (not (theorem-namep 8 (w state))))

(assert! (not (theorem-namep "car-cdr-elim" (w state))))
