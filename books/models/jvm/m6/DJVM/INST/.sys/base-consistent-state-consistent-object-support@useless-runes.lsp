(DJVM::ISARRAYTYPE-NOT-STRINGP)
(DJVM::ISARRAYTYPE-IS-ARRAY-TYPE-NORMALIZE
 (10 2 (:DEFINITION LEN))
 (4 4 (:REWRITE DEFAULT-CDR))
 (4 2 (:REWRITE DEFAULT-+-2))
 (4 2 (:DEFINITION TRUE-LISTP))
 (3 1 (:REWRITE DJVM::WFF-ARRAY-TYPE-IMPLIES-ISARRAYTYPE))
 (2 2 (:TYPE-PRESCRIPTION JVM::WFF-ARRAY-TYPE))
 (2 2 (:REWRITE DEL-SET-LEN))
 (2 2 (:REWRITE DEFAULT-CAR))
 (2 2 (:REWRITE DEFAULT-+-1))
 )
(DJVM::VALID-TYPE-S-IS-INSTANTIATED)
(DJVM::CONSISTENT-OBJECT-VALID-TYPE-STRONG
 (1138 4 (:DEFINITION DJVM::CONSISTENT-JVP))
 (847 8 (:DEFINITION DJVM::CONSISTENT-IMMEDIDATE-INSTANCE))
 (400 8 (:DEFINITION DJVM::CONSISTENT-FIELDS))
 (336 24 (:REWRITE DJVM::WFF-HEAP-STRONG-IMPLIES-ALISTP))
 (336 8 (:DEFINITION DJVM::CONSISTENT-FIELD))
 (264 24 (:DEFINITION JVM::WFF-HEAP-STRONG))
 (240 12 (:DEFINITION ALISTP))
 (236 236 (:REWRITE DEFAULT-CDR))
 (174 174 (:TYPE-PRESCRIPTION JVM::LOADER-INV))
 (144 8 (:DEFINITION DJVM::WFF-FIELD-DECL))
 (135 27 (:DEFINITION LEN))
 (131 131 (:REWRITE DEFAULT-CAR))
 (116 58 (:TYPE-PRESCRIPTION JVM::LOADER-INV-IMPLIES-WFF-STATE))
 (116 58 (:TYPE-PRESCRIPTION JVM::LOADER-INV-IMPLIES-WFF-INSTANCE-CLASS-TABLE))
 (116 58 (:TYPE-PRESCRIPTION JVM::LOADER-INV-IMPLIES-WFF-CLASS-TABLE))
 (104 52 (:DEFINITION NTH))
 (104 26 (:DEFINITION JVM::CLASS-BY-NAME))
 (72 24 (:REWRITE JVM::WFF-HEAP-IMPLIES-ALISTP))
 (64 8 (:DEFINITION JVM::WFF-DATA-FIELD))
 (54 27 (:REWRITE DEFAULT-+-2))
 (48 16 (:DEFINITION JVM::FIELD-FIELDTYPE))
 (32 16 (:DEFINITION TRUE-LISTP))
 (32 8 (:DEFINITION JVM::FIELDS))
 (27 27 (:REWRITE DEL-SET-LEN))
 (27 27 (:REWRITE DEFAULT-+-1))
 (24 8 (:DEFINITION JVM::FIELD-FIELDNAME))
 (16 8 (:DEFINITION JVM::FIELDVALUE))
 (16 8 (:DEFINITION JVM::FIELDNAME))
 (12 3 (:DEFINITION DJVM::ARRAY-OBJ-CONSISTENT1))
 (11 11 (:TYPE-PRESCRIPTION DJVM::CONSISTENT-VALUE))
 (8 8 (:DEFINITION DJVM::WFF-IMMEDIATE-INSTANCE))
 (8 4 (:REWRITE DEFAULT-<-1))
 (4 4 (:TYPE-PRESCRIPTION DJVM::CONSISTENT-FIELDS))
 (4 4 (:REWRITE DEFAULT-<-2))
 (4 4 (:REWRITE DJVM::CONSISTENT-STATE-IMPLIES-NOT-EQUAL-JAVA-LANG-OBJECT-SUPER-BOUNDED))
 (4 1 (:REWRITE DJVM::ISARRAYTYPE-NOT-STRINGP))
 )
(DJVM::CONSISTENT-STATE-NULL-NOT-BOUNDED
 (102 102 (:TYPE-PRESCRIPTION JVM::LOADER-INV))
 (68 34 (:TYPE-PRESCRIPTION JVM::LOADER-INV-IMPLIES-WFF-STATE))
 (68 34 (:TYPE-PRESCRIPTION JVM::LOADER-INV-IMPLIES-WFF-INSTANCE-CLASS-TABLE))
 (68 34 (:TYPE-PRESCRIPTION JVM::LOADER-INV-IMPLIES-WFF-CLASS-TABLE))
 (4 4 (:REWRITE DEFAULT-CAR))
 (2 2 (:REWRITE DEFAULT-CDR))
 )
(DJVM::CLASS-LOADED-CONSISTENT-STATE-IMPLIES-VALID-TYPE-STRONG
 (138 138 (:TYPE-PRESCRIPTION JVM::LOADER-INV))
 (92 46 (:TYPE-PRESCRIPTION JVM::LOADER-INV-IMPLIES-WFF-STATE))
 (92 46 (:TYPE-PRESCRIPTION JVM::LOADER-INV-IMPLIES-WFF-INSTANCE-CLASS-TABLE))
 (92 46 (:TYPE-PRESCRIPTION JVM::LOADER-INV-IMPLIES-WFF-CLASS-TABLE))
 (12 3 (:DEFINITION JVM::CLASS-BY-NAME))
 (6 6 (:REWRITE DEFAULT-CAR))
 (3 3 (:REWRITE DEFAULT-CDR))
 (1 1 (:TYPE-PRESCRIPTION JVM::WFF-ARRAY-TYPE))
 (1 1 (:TYPE-PRESCRIPTION JVM::PRIMITIVE-TYPE?))
 )
