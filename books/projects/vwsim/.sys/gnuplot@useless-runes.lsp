(CONCAT-WITH-SPACE
 (153 45 (:REWRITE DEFAULT-COERCE-3))
 (151 151 (:REWRITE DEFAULT-CDR))
 (117 117 (:REWRITE DEFAULT-COERCE-2))
 (99 72 (:REWRITE DEFAULT-COERCE-1))
 (94 94 (:REWRITE DEFAULT-CAR))
 )
(STRINGP-CONCAT-WITH-SPACE
 (51 15 (:REWRITE DEFAULT-COERCE-3))
 (39 39 (:REWRITE DEFAULT-COERCE-2))
 (35 35 (:REWRITE DEFAULT-CDR))
 (33 24 (:REWRITE DEFAULT-COERCE-1))
 (30 30 (:REWRITE DEFAULT-CAR))
 (21 21 (:TYPE-PRESCRIPTION STRING-APPEND-LST))
 )
(STANDARD-CHAR-STRINGP)
(STANDARD-CHAR-STRING-LISTP
 (5 5 (:REWRITE DEFAULT-CDR))
 (5 5 (:REWRITE DEFAULT-CAR))
 (1 1 (:REWRITE DEFAULT-COERCE-2))
 (1 1 (:REWRITE DEFAULT-COERCE-1))
 )
(STANDARD-CHAR-LISTP-OF-STRINGS
 (99 34 (:REWRITE DEFAULT-COERCE-1))
 (59 59 (:REWRITE DEFAULT-CAR))
 (57 9 (:REWRITE STRINGP-CONCAT-WITH-SPACE))
 (56 56 (:REWRITE DEFAULT-CDR))
 (51 15 (:REWRITE DEFAULT-COERCE-3))
 (49 49 (:REWRITE DEFAULT-COERCE-2))
 (36 6 (:DEFINITION STRING-LISTP))
 (30 30 (:TYPE-PRESCRIPTION STRING-LISTP))
 (22 13 (:TYPE-PRESCRIPTION TRUE-LISTP-APPEND))
 (21 21 (:TYPE-PRESCRIPTION STRING-APPEND-LST))
 (13 13 (:TYPE-PRESCRIPTION BINARY-APPEND))
 (6 3 (:REWRITE COERCE-INVERSE-2))
 )
(RUN-GNUPLOT
 (6502 98 (:DEFINITION CONCAT-WITH-SPACE))
 (1514 675 (:REWRITE DEFAULT-COERCE-1))
 (1254 1076 (:REWRITE DEFAULT-CDR))
 (1201 381 (:REWRITE DEFAULT-COERCE-3))
 (1056 1056 (:REWRITE DEFAULT-COERCE-2))
 (1026 848 (:REWRITE DEFAULT-CAR))
 (291 97 (:DEFINITION STRING-UPCASE1))
 (130 65 (:REWRITE COERCE-INVERSE-2))
 (65 65 (:REWRITE APPEND-TO-NIL))
 (7 1 (:DEFINITION STANDARD-CHAR-STRING-LISTP))
 (3 1 (:DEFINITION STANDARD-CHAR-STRINGP))
 (1 1 (:TYPE-PRESCRIPTION STANDARD-CHAR-LISTP))
 )
