; C Library
;
; Copyright (C) 2025 Kestrel Institute (http://www.kestrel.edu)
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Author: Alessandro Coglio (www.alessandrocoglio.info)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "C2C")

(include-book "../syntax/abstract-syntax-operations")
(include-book "../syntax/unambiguity")
(include-book "../syntax/validation-information")
(include-book "../syntax/langdef-mapping")
(include-book "../atc/symbolic-execution-rules/top")

(include-book "std/lists/index-of" :dir :system)
(include-book "std/system/constant-value" :dir :system)
(include-book "std/system/pseudo-event-form-listp" :dir :system)

(local (include-book "std/system/w" :dir :system))
(local (include-book "std/typed-lists/character-listp" :dir :system))

(local (include-book "kestrel/built-ins/disable" :dir :system))
(local (acl2::disable-most-builtin-logic-defuns))
(local (acl2::disable-builtin-rewrite-rules-for-defaults))
(set-induction-depth-limit 0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Temporary additional symbolic execution rule,
; to support simpadd0's preliminary proof generation capability.

(defruled c::exec-binary-strict-pure-when-add-alt
  (implies (and (equal c::op (c::binop-add))
                (equal c::y (c::expr-value->value eval))
                (equal c::objdes-y (c::expr-value->object eval))
                (not (equal (c::value-kind c::x) :array))
                (not (equal (c::value-kind c::y) :array))
                (equal c::val (c::add-values c::x c::y))
                (c::valuep c::val))
           (equal (c::exec-binary-strict-pure
                   c::op
                   (c::expr-value c::x c::objdes-x)
                   eval)
                  (c::expr-value c::val nil)))
  :use c::exec-binary-strict-pure-when-add)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(xdoc::evmac-topic-implementation

 simpadd0

 :items

 ((xdoc::evmac-topic-implementation-item-input "const-old")

  (xdoc::evmac-topic-implementation-item-input "const-new")

  (xdoc::evmac-topic-implementation-item-input "proofs"))

 :additional

 ("This transformation is implemented as a collection of ACL2 functions
   that operate on the abstract syntax,
   following the recursive structure of the abstract syntax.
   This is a typical pattern for C-to-C transformations,
   which we may want to partially automate,
   via things like generalized `folds' over the abstract syntax."

  "We are also in the process of extending these functions
   to also return events consisting of generated theorems
   (for when proof generation is on).
   The theorems are generated, and designed to be proved,
   in a bottom-up way.
   This is one of a few different or slightly different approaches
   to proof generation, which we are exploring."))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(xdoc::evmac-topic-input-processing simpadd0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-process-inputs (const-old const-new proofs (wrld plist-worldp))
  :returns (mv erp
               (tunits-old transunit-ensemblep)
               (const-old$ symbolp)
               (const-new$ symbolp)
               (proofs$ booleanp))
  :short "Process all the inputs."
  (b* (((reterr) (c$::irr-transunit-ensemble) nil nil nil)
       ((unless (symbolp const-old))
        (reterr (msg "The first input must be a symbol, ~
                      but it is ~x0 instead."
                     const-old)))
       ((unless (symbolp const-new))
        (reterr (msg "The second input must be a symbol, ~
                      but it is ~x0 instead."
                     const-new)))
       ((unless (booleanp proofs))
        (reterr (msg "The :PROOFS input must be a boolean, ~
                      but it is ~x0 instead."
                     proofs)))
       ((unless (acl2::constant-symbolp const-old wrld))
        (reterr (msg "The first input, ~x0, must be a named constant, ~
                      but it is not."
                     const-old)))
       (tunits-old (acl2::constant-value const-old wrld))
       ((unless (transunit-ensemblep tunits-old))
        (reterr (msg "The value of the constant ~x0 ~
                      must be a translation unit ensemble, ~
                      but it is ~x1 instead."
                     const-old tunits-old)))
       ((unless (transunit-ensemble-unambp tunits-old))
        (reterr (msg "The translation unit ensemble ~x0 ~
                      that is the value of the constant ~x1 ~
                      must be unambiguous, ~
                      but it is not."
                     tunits-old const-old)))
       ((unless (transunit-ensemble-annop tunits-old))
        (reterr (msg "The translation unit ensemble ~x0 ~
                      that is the value of the constant ~x1 ~
                      must contains validation information, ~
                      but it does not."
                     tunits-old const-old))))
    (retok tunits-old const-old const-new proofs))

  ///

  (defret transunit-ensemble-unambp-of-simpadd0-process-inputs
    (implies (not erp)
             (transunit-ensemble-unambp tunits-old)))

  (defret transunit-ensemble-annop-of-simpadd0-process-inputs
    (implies (not erp)
             (transunit-ensemble-annop tunits-old))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(xdoc::evmac-topic-event-generation simpadd0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defines simpadd0-exprs/decls/stmts
  :short "Transform expressions, declarations, statements,
          and related entities."

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-expr ((expr exprp))
    :guard (expr-unambp expr)
    :returns (mv (new-expr exprp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an expression."
    (expr-case
     expr
     :ident (mv (expr-fix expr) nil)
     :const (mv (expr-fix expr) nil)
     :string (mv (expr-fix expr) nil)
     :paren
     (b* (((mv new-inner events-inner) (simpadd0-expr expr.inner)))
       (mv (expr-paren new-inner) events-inner))
     :gensel
     (b* (((mv new-control events-control) (simpadd0-expr expr.control))
          ((mv new-assocs events-assocs) (simpadd0-genassoc-list expr.assocs)))
       (mv (make-expr-gensel :control new-control
                             :assocs new-assocs)
           (append events-control events-assocs)))
     :arrsub
     (b* (((mv new-arg1 events-arg1) (simpadd0-expr expr.arg1))
          ((mv new-arg2 events-arg2) (simpadd0-expr expr.arg2)))
       (mv (make-expr-arrsub :arg1 new-arg1
                             :arg2 new-arg2)
           (append events-arg1 events-arg2)))
     :funcall
     (b* (((mv new-fun events-fun) (simpadd0-expr expr.fun))
          ((mv new-args events-args) (simpadd0-expr-list expr.args)))
       (mv (make-expr-funcall :fun new-fun
                              :args new-args)
           (append events-fun events-args)))
     :member
     (b* (((mv new-arg events-arg) (simpadd0-expr expr.arg)))
       (mv (make-expr-member :arg new-arg
                             :name expr.name)
           events-arg))
     :memberp
     (b* (((mv new-arg events-arg) (simpadd0-expr expr.arg)))
       (mv (make-expr-memberp :arg new-arg
                              :name expr.name)
           events-arg))
     :complit
     (b* (((mv new-type events-type) (simpadd0-tyname expr.type))
          ((mv new-elems events-elems) (simpadd0-desiniter-list expr.elems)))
       (mv (make-expr-complit :type new-type
                              :elems new-elems
                              :final-comma expr.final-comma)
           (append events-type events-elems)))
     :unary
     (b* (((mv new-arg events-arg) (simpadd0-expr expr.arg)))
       (mv (make-expr-unary :op expr.op
                            :arg new-arg)
           events-arg))
     :sizeof
     (b* (((mv new-type events-type) (simpadd0-tyname expr.type)))
       (mv (expr-sizeof new-type)
           events-type))
     :sizeof-ambig (prog2$ (impossible) (mv (irr-expr) nil))
     :alignof
     (b* (((mv new-type events-type) (simpadd0-tyname expr.type)))
       (mv (make-expr-alignof :type new-type
                              :uscores expr.uscores)
           events-type))
     :cast
     (b* (((mv new-type events-type) (simpadd0-tyname expr.type))
          ((mv new-arg events-arg) (simpadd0-expr expr.arg)))
       (mv (make-expr-cast :type new-type
                           :arg new-arg)
           (append events-type events-arg)))
     :binary
     (b* (((mv new-arg1 events-arg1) (simpadd0-expr expr.arg1))
          ((mv new-arg2 events-arg2) (simpadd0-expr expr.arg2)))
       (if (and (c$::expr-zerop new-arg2)
                (expr-case new-arg1 :ident)
                (b* (((c$::var-info info)
                      (c$::coerce-var-info
                       (c$::expr-ident->info new-arg1))))
                  (c$::type-case info.type :sint)))
           (mv new-arg1 (append events-arg1 events-arg2))
         (mv (make-expr-binary :op expr.op :arg1 new-arg1 :arg2 new-arg2)
             (append events-arg1 events-arg2))))
     :cond
     (b* (((mv new-test events-test) (simpadd0-expr expr.test))
          ((mv new-then events-then) (simpadd0-expr-option expr.then))
          ((mv new-else events-else) (simpadd0-expr expr.else)))
       (mv (make-expr-cond :test new-test
                           :then new-then
                           :else new-else)
           (append events-test events-then events-else)))
     :comma
     (b* (((mv new-first events-first) (simpadd0-expr expr.first))
          ((mv new-next events-next) (simpadd0-expr expr.next)))
       (mv (make-expr-comma :first new-first
                            :next new-next)
           (append events-first events-next)))
     :cast/call-ambig (prog2$ (impossible) (mv (irr-expr) nil))
     :cast/mul-ambig (prog2$ (impossible) (mv (irr-expr) nil))
     :cast/add-ambig (prog2$ (impossible) (mv (irr-expr) nil))
     :cast/sub-ambig (prog2$ (impossible) (mv (irr-expr) nil))
     :cast/and-ambig (prog2$ (impossible) (mv (irr-expr) nil))
     :stmt
     (b* (((mv new-items events-items) (simpadd0-block-item-list expr.items)))
       (mv (expr-stmt new-items)
           events-items))
     :tycompat
     (b* (((mv new-type1 events-type1) (simpadd0-tyname expr.type1))
          ((mv new-type2 events-type2) (simpadd0-tyname expr.type2)))
       (mv (make-expr-tycompat :type1 new-type1
                               :type2 new-type2)
           (append events-type1 events-type2)))
     :offsetof
     (b* (((mv new-type events-type) (simpadd0-tyname expr.type))
          ((mv new-member events-member)
           (simpadd0-member-designor expr.member)))
       (mv (make-expr-offsetof :type new-type
                               :member new-member)
           (append events-type events-member)))
     :va-arg
     (b* (((mv new-list events-list) (simpadd0-expr expr.list))
          ((mv new-type events-type) (simpadd0-tyname expr.type)))
       (mv (make-expr-va-arg :list new-list
                             :type new-type)
           (append events-list events-type)))
     :extension
     (b* (((mv new-expr events-expr) (simpadd0-expr expr.expr)))
       (mv (expr-extension new-expr)
           events-expr)))
    :measure (expr-count expr))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-expr-list ((exprs expr-listp))
    :guard (expr-list-unambp exprs)
    :returns (mv (new-exprs expr-listp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of expressions."
    (b* (((when (endp exprs)) (mv nil nil))
         ((mv new-expr events-expr) (simpadd0-expr (car exprs)))
         ((mv new-exprs events-exprs) (simpadd0-expr-list (cdr exprs))))
      (mv (cons new-expr new-exprs)
          (append events-expr events-exprs)))
    :measure (expr-list-count exprs))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-expr-option ((expr? expr-optionp))
    :guard (expr-option-unambp expr?)
    :returns (mv (new-expr? expr-optionp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an optional expression."
    (expr-option-case
     expr?
     :some (simpadd0-expr expr?.val)
     :none (mv nil nil))
    :measure (expr-option-count expr?))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-const-expr ((cexpr const-exprp))
    :guard (const-expr-unambp cexpr)
    :returns (mv (new-cexpr const-exprp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a constant expression."
    (b* (((mv new-expr events-expr) (simpadd0-expr (const-expr->expr cexpr))))
      (mv (const-expr new-expr)
          events-expr))
    :measure (const-expr-count cexpr))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-const-expr-option ((cexpr? const-expr-optionp))
    :guard (const-expr-option-unambp cexpr?)
    :returns (mv (new-cexpr? const-expr-optionp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an optional constant expression."
    (const-expr-option-case
     cexpr?
     :some (simpadd0-const-expr cexpr?.val)
     :none (mv nil nil))
    :measure (const-expr-option-count cexpr?))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-genassoc ((genassoc genassocp))
    :guard (genassoc-unambp genassoc)
    :returns (mv (new-genassoc genassocp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a generic association."
    (genassoc-case
     genassoc
     :type
     (b* (((mv new-type events-type) (simpadd0-tyname genassoc.type))
          ((mv new-expr events-expr) (simpadd0-expr genassoc.expr)))
       (mv (make-genassoc-type :type new-type
                               :expr new-expr)
           (append events-type events-expr)))
     :default
     (b* (((mv new-expr events-expr) (simpadd0-expr genassoc.expr)))
       (mv (genassoc-default new-expr)
           events-expr)))
    :measure (genassoc-count genassoc))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-genassoc-list ((genassocs genassoc-listp))
    :guard (genassoc-list-unambp genassocs)
    :returns (mv (new-genassocs genassoc-listp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of generic associations."
    (b* (((when (endp genassocs)) (mv nil nil))
         ((mv new-assoc events-assoc)
          (simpadd0-genassoc (car genassocs)))
         ((mv new-assocs events-assocs)
          (simpadd0-genassoc-list (cdr genassocs))))
      (mv (cons new-assoc new-assocs)
          (append events-assoc events-assocs)))
    :measure (genassoc-list-count genassocs))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-member-designor ((memdes member-designorp))
    :guard (member-designor-unambp memdes)
    :returns (mv (new-memdes member-designorp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a member designator."
    (member-designor-case
     memdes
     :ident (mv (member-designor-fix memdes) nil)
     :dot
     (b* (((mv new-member events-member)
           (simpadd0-member-designor memdes.member)))
       (mv (make-member-designor-dot :member new-member
                                     :name memdes.name)
           events-member))
     :sub
     (b* (((mv new-member events-member)
           (simpadd0-member-designor memdes.member))
          ((mv new-index events-index)
           (simpadd0-expr memdes.index)))
       (mv (make-member-designor-sub :member new-member
                                     :index new-index)
           (append events-member events-index))))
    :measure (member-designor-count memdes))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-type-spec ((tyspec type-specp))
    :guard (type-spec-unambp tyspec)
    :returns (mv (new-tyspec type-specp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a type specifier."
    (type-spec-case
     tyspec
     :void (mv (type-spec-fix tyspec) nil)
     :char (mv (type-spec-fix tyspec) nil)
     :short (mv (type-spec-fix tyspec) nil)
     :int (mv (type-spec-fix tyspec) nil)
     :long (mv (type-spec-fix tyspec) nil)
     :float (mv (type-spec-fix tyspec) nil)
     :double (mv (type-spec-fix tyspec) nil)
     :signed (mv (type-spec-fix tyspec) nil)
     :unsigned (mv (type-spec-fix tyspec) nil)
     :bool (mv (type-spec-fix tyspec) nil)
     :complex (mv (type-spec-fix tyspec) nil)
     :atomic (b* (((mv new-type events-type) (simpadd0-tyname tyspec.type)))
               (mv (type-spec-atomic new-type)
                   events-type))
     :struct (b* (((mv new-spec events-spec)
                   (simpadd0-strunispec tyspec.spec)))
               (mv (type-spec-struct new-spec)
                   events-spec))
     :union (b* (((mv new-spec events-spec)
                  (simpadd0-strunispec tyspec.spec)))
              (mv (type-spec-union new-spec)
                  events-spec))
     :enum (b* (((mv new-spec events-spec)
                 (simpadd0-enumspec tyspec.spec)))
             (mv (type-spec-enum new-spec)
                 events-spec))
     :typedef (mv (type-spec-fix tyspec) nil)
     :int128 (mv (type-spec-fix tyspec) nil)
     :float32 (mv (type-spec-fix tyspec) nil)
     :float32x (mv (type-spec-fix tyspec) nil)
     :float64 (mv (type-spec-fix tyspec) nil)
     :float64x (mv (type-spec-fix tyspec) nil)
     :float128 (mv (type-spec-fix tyspec) nil)
     :float128x (mv (type-spec-fix tyspec) nil)
     :builtin-va-list (mv (type-spec-fix tyspec) nil)
     :struct-empty (mv (type-spec-fix tyspec) nil)
     :typeof-expr (b* (((mv new-expr events-expr) (simpadd0-expr tyspec.expr)))
                    (mv (make-type-spec-typeof-expr :expr new-expr
                                                    :uscores tyspec.uscores)
                        events-expr))
     :typeof-type (b* (((mv new-type events-type)
                        (simpadd0-tyname tyspec.type)))
                    (mv (make-type-spec-typeof-type :type new-type
                                                    :uscores tyspec.uscores)
                        events-type))
     :typeof-ambig (prog2$ (impossible) (mv (irr-type-spec) nil))
     :auto-type (mv (type-spec-fix tyspec) nil))
    :measure (type-spec-count tyspec))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-spec/qual ((specqual spec/qual-p))
    :guard (spec/qual-unambp specqual)
    :returns (mv (new-specqual spec/qual-p)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a type specifier or qualifier."
    (spec/qual-case
     specqual
     :typespec (b* (((mv new-spec events-spec)
                     (simpadd0-type-spec specqual.spec)))
                 (mv (spec/qual-typespec new-spec)
                     events-spec))
     :typequal (mv (spec/qual-fix specqual) nil)
     :align (b* (((mv new-spec events-spec)
                  (simpadd0-align-spec specqual.spec)))
              (mv (spec/qual-align new-spec)
                  events-spec))
     :attrib (mv (spec/qual-fix specqual) nil))
    :measure (spec/qual-count specqual))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-spec/qual-list ((specquals spec/qual-listp))
    :guard (spec/qual-list-unambp specquals)
    :returns (mv (new-specquals spec/qual-listp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of type specifiers and qualifiers."
    (b* (((when (endp specquals)) (mv nil nil))
         ((mv new-specqual events-specqual)
          (simpadd0-spec/qual (car specquals)))
         ((mv new-specquals events-specquals)
          (simpadd0-spec/qual-list (cdr specquals))))
      (mv (cons new-specqual new-specquals)
          (append events-specqual events-specquals)))
    :measure (spec/qual-list-count specquals))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-align-spec ((alignspec align-specp))
    :guard (align-spec-unambp alignspec)
    :returns (mv (new-alignspec align-specp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an alignment specifier."
    (align-spec-case
     alignspec
     :alignas-type (b* (((mv new-type events-type)
                         (simpadd0-tyname alignspec.type)))
                     (mv (align-spec-alignas-type new-type)
                         events-type))
     :alignas-expr (b* (((mv new-expr events-expr)
                         (simpadd0-const-expr alignspec.expr)))
                     (mv (align-spec-alignas-expr new-expr)
                         events-expr))
     :alignas-ambig (prog2$ (impossible) (mv (irr-align-spec) nil)))
    :measure (align-spec-count alignspec))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-decl-spec ((declspec decl-specp))
    :guard (decl-spec-unambp declspec)
    :returns (mv (new-declspec decl-specp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a declaration specifier."
    (decl-spec-case
     declspec
     :stoclass (mv (decl-spec-fix declspec) nil)
     :typespec (b* (((mv new-spec events-spec)
                     (simpadd0-type-spec declspec.spec)))
                 (mv (decl-spec-typespec new-spec)
                     events-spec))
     :typequal (mv (decl-spec-fix declspec) nil)
     :function (mv (decl-spec-fix declspec) nil)
     :align (b* (((mv new-spec events-spec)
                  (simpadd0-align-spec declspec.spec)))
              (mv (decl-spec-align new-spec)
                  events-spec))
     :attrib (mv (decl-spec-fix declspec) nil)
     :stdcall (mv (decl-spec-fix declspec) nil)
     :declspec (mv (decl-spec-fix declspec) nil))
    :measure (decl-spec-count declspec))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-decl-spec-list ((declspecs decl-spec-listp))
    :guard (decl-spec-list-unambp declspecs)
    :returns (mv (new-declspecs decl-spec-listp)
                 (event pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of declaration specifiers."
    (b* (((when (endp declspecs)) (mv nil nil))
         ((mv new-declspec events-declspec)
          (simpadd0-decl-spec (car declspecs)))
         ((mv new-declspecs events-declspecs)
          (simpadd0-decl-spec-list (cdr declspecs))))
      (mv (cons new-declspec new-declspecs)
          (append events-declspec events-declspecs)))
    :measure (decl-spec-list-count declspecs))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-initer ((initer initerp))
    :guard (initer-unambp initer)
    :returns (mv (new-initer initerp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an initializer."
    (initer-case
     initer
     :single (b* (((mv new-expr events-expr) (simpadd0-expr initer.expr)))
               (mv (initer-single new-expr)
                   events-expr))
     :list (b* (((mv new-elems events-elems)
                 (simpadd0-desiniter-list initer.elems)))
             (mv (make-initer-list :elems new-elems
                                   :final-comma initer.final-comma)
                 events-elems)))
    :measure (initer-count initer))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-initer-option ((initer? initer-optionp))
    :guard (initer-option-unambp initer?)
    :returns (mv (new-initer? initer-optionp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an optional initializer."
    (initer-option-case
     initer?
     :some (simpadd0-initer initer?.val)
     :none (mv nil nil))
    :measure (initer-option-count initer?))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-desiniter ((desiniter desiniterp))
    :guard (desiniter-unambp desiniter)
    :returns (mv (new-desiniter desiniterp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an initializer with optional designations."
    (b* (((desiniter desiniter) desiniter)
         ((mv new-designors events-designors)
          (simpadd0-designor-list desiniter.designors))
         ((mv new-initer events-initer)
          (simpadd0-initer desiniter.initer)))
      (mv (make-desiniter :designors new-designors
                          :initer new-initer)
          (append events-designors events-initer)))
    :measure (desiniter-count desiniter))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-desiniter-list ((desiniters desiniter-listp))
    :guard (desiniter-list-unambp desiniters)
    :returns (mv (new-desiniters desiniter-listp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of initializers with optional designations."
    (b* (((when (endp desiniters)) (mv nil nil))
         ((mv new-desiniter events-desiniter)
          (simpadd0-desiniter (car desiniters)))
         ((mv new-desiniters events-desiniters)
          (simpadd0-desiniter-list (cdr desiniters))))
      (mv (cons new-desiniter new-desiniters)
          (append events-desiniter events-desiniters)))
    :measure (desiniter-list-count desiniters))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-designor ((designor designorp))
    :guard (designor-unambp designor)
    :returns (mv (new-designor designorp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a designator."
    (designor-case
     designor
     :sub (b* (((mv new-index events-index)
                (simpadd0-const-expr designor.index)))
            (mv (designor-sub new-index)
                events-index))
     :dot (mv (designor-fix designor) nil))
    :measure (designor-count designor))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-designor-list ((designors designor-listp))
    :guard (designor-list-unambp designors)
    :returns (mv (new-designors designor-listp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of designators."
    (b* (((when (endp designors)) (mv nil nil))
         ((mv new-designor events-designor)
          (simpadd0-designor (car designors)))
         ((mv new-designors events-designors)
          (simpadd0-designor-list (cdr designors))))
      (mv (cons new-designor new-designors)
          (append events-designor events-designors)))
    :measure (designor-list-count designors))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-declor ((declor declorp))
    :guard (declor-unambp declor)
    :returns (mv (new-declor declorp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a declarator."
    (b* (((declor declor) declor)
         ((mv new-direct events-direct)
          (simpadd0-dirdeclor declor.direct)))
      (mv (make-declor :pointers declor.pointers
                       :direct new-direct)
          events-direct))
    :measure (declor-count declor))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-declor-option ((declor? declor-optionp))
    :guard (declor-option-unambp declor?)
    :returns (mv (new-declor? declor-optionp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an optional declarator."
    (declor-option-case
     declor?
     :some (simpadd0-declor declor?.val)
     :none (mv nil nil))
    :measure (declor-option-count declor?))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-dirdeclor ((dirdeclor dirdeclorp))
    :guard (dirdeclor-unambp dirdeclor)
    :returns (mv (new-dirdeclor dirdeclorp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a direct declarator."
    (dirdeclor-case
     dirdeclor
     :ident (mv (dirdeclor-fix dirdeclor) nil)
     :paren (b* (((mv new-declor events-declor)
                  (simpadd0-declor dirdeclor.unwrap)))
              (mv (dirdeclor-paren new-declor)
                  events-declor))
     :array (b* (((mv new-decl events-decl)
                  (simpadd0-dirdeclor dirdeclor.decl))
                 ((mv new-expr? events-expr?)
                  (simpadd0-expr-option dirdeclor.expr?)))
              (mv (make-dirdeclor-array :decl new-decl
                                        :tyquals dirdeclor.tyquals
                                        :expr? new-expr?)
                  (append events-decl events-expr?)))
     :array-static1 (b* (((mv new-decl events-decl)
                          (simpadd0-dirdeclor dirdeclor.decl))
                         ((mv new-expr events-expr)
                          (simpadd0-expr dirdeclor.expr)))
                      (mv (make-dirdeclor-array-static1 :decl new-decl
                                                        :tyquals dirdeclor.tyquals
                                                        :expr new-expr)
                          (append events-decl events-expr)))
     :array-static2 (b* (((mv new-decl events-decl)
                          (simpadd0-dirdeclor dirdeclor.decl))
                         ((mv new-expr events-expr)
                          (simpadd0-expr dirdeclor.expr)))
                      (mv (make-dirdeclor-array-static2 :decl new-decl
                                                        :tyquals dirdeclor.tyquals
                                                        :expr new-expr)
                          (append events-decl events-expr)))
     :array-star (b* (((mv new-decl events-decl)
                       (simpadd0-dirdeclor dirdeclor.decl)))
                   (mv (make-dirdeclor-array-star :decl new-decl
                                                  :tyquals dirdeclor.tyquals)
                       events-decl))
     :function-params (b* (((mv new-decl events-decl)
                            (simpadd0-dirdeclor dirdeclor.decl))
                           ((mv new-params events-params)
                            (simpadd0-paramdecl-list dirdeclor.params)))
                        (mv (make-dirdeclor-function-params
                             :decl new-decl
                             :params new-params
                             :ellipsis dirdeclor.ellipsis)
                            (append events-decl events-params)))
     :function-names (b* (((mv new-decl events-decl)
                           (simpadd0-dirdeclor dirdeclor.decl)))
                       (mv (make-dirdeclor-function-names
                            :decl new-decl
                            :names dirdeclor.names)
                           events-decl)))
    :measure (dirdeclor-count dirdeclor))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-absdeclor ((absdeclor absdeclorp))
    :guard (absdeclor-unambp absdeclor)
    :returns (mv (new-absdeclor absdeclorp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an abstract declarator."
    (b* (((absdeclor absdeclor) absdeclor)
         ((mv new-decl? events-decl?)
          (simpadd0-dirabsdeclor-option absdeclor.decl?)))
      (mv (make-absdeclor :pointers absdeclor.pointers
                          :decl? new-decl?)
          events-decl?))
    :measure (absdeclor-count absdeclor))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-absdeclor-option ((absdeclor? absdeclor-optionp))
    :guard (absdeclor-option-unambp absdeclor?)
    :returns (mv (new-absdeclor? absdeclor-optionp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an optional abstract declarator."
    (absdeclor-option-case
     absdeclor?
     :some (simpadd0-absdeclor absdeclor?.val)
     :none (mv nil nil))
    :measure (absdeclor-option-count absdeclor?))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-dirabsdeclor ((dirabsdeclor dirabsdeclorp))
    :guard (dirabsdeclor-unambp dirabsdeclor)
    :returns (mv (new-dirabsdeclor dirabsdeclorp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a direct abstract declarator."
    (dirabsdeclor-case
     dirabsdeclor
     :dummy-base (prog2$
                  (raise "Misusage error: ~x0." (dirabsdeclor-fix dirabsdeclor))
                  (mv (irr-dirabsdeclor) nil))
     :paren (b* (((mv new-inner events-inner)
                  (simpadd0-absdeclor dirabsdeclor.unwrap)))
              (mv (dirabsdeclor-paren new-inner)
                  events-inner))
     :array (b* (((mv new-decl? events-decl?)
                  (simpadd0-dirabsdeclor-option dirabsdeclor.decl?))
                 ((mv new-expr? events-expr?)
                  (simpadd0-expr-option dirabsdeclor.expr?)))
              (mv (make-dirabsdeclor-array :decl? new-decl?
                                           :tyquals dirabsdeclor.tyquals
                                           :expr? new-expr?)
                  (append events-decl? events-expr?)))
     :array-static1 (b* (((mv new-decl? events-decl?)
                          (simpadd0-dirabsdeclor-option dirabsdeclor.decl?))
                         ((mv new-expr events-expr)
                          (simpadd0-expr dirabsdeclor.expr)))
                      (mv (make-dirabsdeclor-array-static1
                           :decl? new-decl?
                           :tyquals dirabsdeclor.tyquals
                           :expr new-expr)
                          (append events-decl? events-expr)))
     :array-static2 (b* (((mv new-decl? events-decl?)
                          (simpadd0-dirabsdeclor-option dirabsdeclor.decl?))
                         ((mv new-expr events-expr)
                          (simpadd0-expr dirabsdeclor.expr)))
                      (mv (make-dirabsdeclor-array-static2
                           :decl? new-decl?
                           :tyquals dirabsdeclor.tyquals
                           :expr new-expr)
                          (append events-decl? events-expr)))
     :array-star (b* (((mv new-decl? events-decl?)
                       (simpadd0-dirabsdeclor-option dirabsdeclor.decl?)))
                   (mv (dirabsdeclor-array-star new-decl?)
                       events-decl?))
     :function (b* (((mv new-decl? events-decl?)
                     (simpadd0-dirabsdeclor-option dirabsdeclor.decl?))
                    ((mv new-params events-params)
                     (simpadd0-paramdecl-list dirabsdeclor.params)))
                 (mv (make-dirabsdeclor-function
                      :decl? new-decl?
                      :params new-params
                      :ellipsis dirabsdeclor.ellipsis)
                     (append events-decl? events-params))))
    :measure (dirabsdeclor-count dirabsdeclor))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-dirabsdeclor-option ((dirabsdeclor? dirabsdeclor-optionp))
    :guard (dirabsdeclor-option-unambp dirabsdeclor?)
    :returns (mv (new-dirabsdeclor? dirabsdeclor-optionp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an optional direct abstract declarator."
    (dirabsdeclor-option-case
     dirabsdeclor?
     :some (simpadd0-dirabsdeclor dirabsdeclor?.val)
     :none (mv nil nil))
    :measure (dirabsdeclor-option-count dirabsdeclor?))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-paramdecl ((paramdecl paramdeclp))
    :guard (paramdecl-unambp paramdecl)
    :returns (mv (new-paramdecl paramdeclp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a parameter declaration."
    (b* (((paramdecl paramdecl) paramdecl)
         ((mv new-spec events-spec) (simpadd0-decl-spec-list paramdecl.spec))
         ((mv new-decl events-decl) (simpadd0-paramdeclor paramdecl.decl)))
      (mv (make-paramdecl :spec new-spec
                          :decl new-decl)
          (append events-spec events-decl)))
    :measure (paramdecl-count paramdecl))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-paramdecl-list ((paramdecls paramdecl-listp))
    :guard (paramdecl-list-unambp paramdecls)
    :returns (mv (new-paramdecls paramdecl-listp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of parameter declarations."
    (b* (((when (endp paramdecls)) (mv nil nil))
         ((mv new-paramdecl events-paramdecl)
          (simpadd0-paramdecl (car paramdecls)))
         ((mv new-paramdecls events-paramdecls)
          (simpadd0-paramdecl-list (cdr paramdecls))))
      (mv (cons new-paramdecl new-paramdecls)
          (append events-paramdecl events-paramdecls)))
    :measure (paramdecl-list-count paramdecls))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-paramdeclor ((paramdeclor paramdeclorp))
    :guard (paramdeclor-unambp paramdeclor)
    :returns (mv (new-paramdeclor paramdeclorp)
                 (events-paramdecls pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a parameter declarator."
    (paramdeclor-case
     paramdeclor
     :declor (b* (((mv new-declor events-declor)
                   (simpadd0-declor paramdeclor.unwrap)))
               (mv (paramdeclor-declor new-declor)
                   events-declor))
     :absdeclor (b* (((mv new-absdeclor events-absdeclor)
                      (simpadd0-absdeclor paramdeclor.unwrap)))
                  (mv (paramdeclor-absdeclor new-absdeclor)
                      events-absdeclor))
     :none (mv (paramdeclor-none) nil)
     :ambig (prog2$ (impossible) (mv (irr-paramdeclor) nil)))
    :measure (paramdeclor-count paramdeclor))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-tyname ((tyname tynamep))
    :guard (tyname-unambp tyname)
    :returns (mv (new-tyname tynamep)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a type name."
    (b* (((tyname tyname) tyname)
         ((mv new-specqual events-specqual)
          (simpadd0-spec/qual-list tyname.specqual))
         ((mv new-decl? events-decl?)
          (simpadd0-absdeclor-option tyname.decl?)))
      (mv (make-tyname :specqual new-specqual
                       :decl? new-decl?)
          (append events-specqual events-decl?)))
    :measure (tyname-count tyname))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-strunispec ((strunispec strunispecp))
    :guard (strunispec-unambp strunispec)
    :returns (mv (new-strunispec strunispecp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a structure or union specifier."
    (b* (((strunispec strunispec) strunispec)
         ((mv new-members events-members)
          (simpadd0-structdecl-list strunispec.members)))
      (mv (make-strunispec :name strunispec.name
                           :members new-members)
          events-members))
    :measure (strunispec-count strunispec))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-structdecl ((structdecl structdeclp))
    :guard (structdecl-unambp structdecl)
    :returns (mv (new-structdecl structdeclp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a structure declaration."
    (structdecl-case
     structdecl
     :member (b* (((mv new-specqual events-specqual)
                   (simpadd0-spec/qual-list structdecl.specqual))
                  ((mv new-declor events-declor)
                   (simpadd0-structdeclor-list structdecl.declor)))
               (mv (make-structdecl-member
                    :extension structdecl.extension
                    :specqual new-specqual
                    :declor new-declor
                    :attrib structdecl.attrib)
                   (append events-specqual events-declor)))
     :statassert (b* (((mv new-structdecl events-structdecl)
                       (simpadd0-statassert structdecl.unwrap)))
                   (mv (structdecl-statassert new-structdecl)
                       events-structdecl))
     :empty (mv (structdecl-empty) nil))
    :measure (structdecl-count structdecl))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-structdecl-list ((structdecls structdecl-listp))
    :guard (structdecl-list-unambp structdecls)
    :returns (mv (new-structdecls structdecl-listp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of structure declarations."
    (b* (((when (endp structdecls)) (mv nil nil))
         ((mv new-structdecl events-structdecl)
          (simpadd0-structdecl (car structdecls)))
         ((mv new-structdecls events-structdecls)
          (simpadd0-structdecl-list (cdr structdecls))))
      (mv (cons new-structdecl new-structdecls)
          (append events-structdecl events-structdecls)))
    :measure (structdecl-list-count structdecls))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-structdeclor ((structdeclor structdeclorp))
    :guard (structdeclor-unambp structdeclor)
    :returns (mv (new-structdeclor structdeclorp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a structure declarator."
    (b* (((structdeclor structdeclor) structdeclor)
         ((mv new-declor? events-declor?)
          (simpadd0-declor-option structdeclor.declor?))
         ((mv new-expr? events-expr?)
          (simpadd0-const-expr-option structdeclor.expr?)))
      (mv (make-structdeclor :declor? new-declor?
                             :expr? new-expr?)
          (append events-declor? events-expr?)))
    :measure (structdeclor-count structdeclor))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-structdeclor-list ((structdeclors structdeclor-listp))
    :guard (structdeclor-list-unambp structdeclors)
    :returns (mv (new-structdeclors structdeclor-listp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of structure declarators."
    (b* (((when (endp structdeclors)) (mv nil nil))
         ((mv new-structdeclor events-structdeclor)
          (simpadd0-structdeclor (car structdeclors)))
         ((mv new-structdeclors events-structdeclors)
          (simpadd0-structdeclor-list (cdr structdeclors))))
      (mv (cons new-structdeclor new-structdeclors)
          (append events-structdeclor events-structdeclors)))
    :measure (structdeclor-list-count structdeclors))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-enumspec ((enumspec enumspecp))
    :guard (enumspec-unambp enumspec)
    :returns (mv (new-enumspec enumspecp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an enumeration specifier."
    (b* (((enumspec enumspec) enumspec)
         ((mv new-list events-list) (simpadd0-enumer-list enumspec.list)))
      (mv (make-enumspec :name enumspec.name
                         :list new-list
                         :final-comma enumspec.final-comma)
          events-list))
    :measure (enumspec-count enumspec))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-enumer ((enumer enumerp))
    :guard (enumer-unambp enumer)
    :returns (mv (new-enumer enumerp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an enumerator."
    (b* (((enumer enumer) enumer)
         ((mv new-value events-value)
          (simpadd0-const-expr-option enumer.value)))
      (mv (make-enumer :name enumer.name
                       :value new-value)
          events-value))
    :measure (enumer-count enumer))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-enumer-list ((enumers enumer-listp))
    :guard (enumer-list-unambp enumers)
    :returns (mv (new-enumers enumer-listp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of enumerators."
    (b* (((when (endp enumers)) (mv nil nil))
         ((mv new-enumer events-enumer) (simpadd0-enumer (car enumers)))
         ((mv new-enumers events-enumers) (simpadd0-enumer-list (cdr enumers))))
      (mv (cons new-enumer new-enumers)
          (append events-enumer events-enumers)))
    :measure (enumer-list-count enumers))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-statassert ((statassert statassertp))
    :guard (statassert-unambp statassert)
    :returns (mv (new-statassert statassertp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an static assertion declaration."
    (b* (((statassert statassert) statassert)
         ((mv new-test events-test) (simpadd0-const-expr statassert.test)))
      (mv (make-statassert :test new-test
                           :message statassert.message)
          events-test))
    :measure (statassert-count statassert))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-initdeclor ((initdeclor initdeclorp))
    :guard (initdeclor-unambp initdeclor)
    :returns (mv (new-initdeclor initdeclorp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform an initializer declarator."
    (b* (((initdeclor initdeclor) initdeclor)
         ((mv new-declor events-declor)
          (simpadd0-declor initdeclor.declor))
         ((mv new-init? events-init?)
          (simpadd0-initer-option initdeclor.init?)))
      (mv (make-initdeclor :declor new-declor
                           :asm? initdeclor.asm?
                           :attribs initdeclor.attribs
                           :init? new-init?)
          (append events-declor events-init?)))
    :measure (initdeclor-count initdeclor))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-initdeclor-list ((initdeclors initdeclor-listp))
    :guard (initdeclor-list-unambp initdeclors)
    :returns (mv (new-initdeclors initdeclor-listp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of initializer declarators."
    (b* (((when (endp initdeclors)) (mv nil nil))
         ((mv new-initdeclor events-initdeclor)
          (simpadd0-initdeclor (car initdeclors)))
         ((mv new-initdeclors events-initdeclors)
          (simpadd0-initdeclor-list (cdr initdeclors))))
      (mv (cons new-initdeclor new-initdeclors)
          (append events-initdeclor events-initdeclors)))
    :measure (initdeclor-list-count initdeclors))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-decl ((decl declp))
    :guard (decl-unambp decl)
    :returns (mv (new-decl declp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a declaration."
    (decl-case
     decl
     :decl (b* (((mv new-specs events-specs)
                 (simpadd0-decl-spec-list decl.specs))
                ((mv new-init events-init)
                 (simpadd0-initdeclor-list decl.init)))
             (mv (make-decl-decl :extension decl.extension
                                 :specs new-specs
                                 :init new-init)
                 (append events-specs events-init)))
     :statassert (b* (((mv new-decl events-decl)
                       (simpadd0-statassert decl.unwrap)))
                   (mv (decl-statassert new-decl)
                       events-decl)))
    :measure (decl-count decl))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-decl-list ((decls decl-listp))
    :guard (decl-list-unambp decls)
    :returns (mv (new-decls decl-listp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of declarations."
    (b* (((when (endp decls)) (mv nil nil))
         ((mv new-decl events-decl) (simpadd0-decl (car decls)))
         ((mv new-decls events-decls) (simpadd0-decl-list (cdr decls))))
      (mv (cons new-decl new-decls)
          (append events-decl events-decls)))
    :measure (decl-list-count decls))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-label ((label labelp))
    :guard (label-unambp label)
    :returns (mv (new-label labelp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a label."
    (label-case
     label
     :name (mv (label-fix label) nil)
     :casexpr (b* (((mv new-expr events-expr)
                    (simpadd0-const-expr label.expr))
                   ((mv new-range? events-range?)
                    (simpadd0-const-expr-option label.range?)))
                (mv (make-label-casexpr :expr new-expr
                                        :range? new-range?)
                    (append events-expr events-range?)))
     :default (mv (label-fix label) nil))
    :measure (label-count label))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-stmt ((stmt stmtp))
    :guard (stmt-unambp stmt)
    :returns (mv (new-stmt stmtp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a statement."
    (stmt-case
     stmt
     :labeled (b* (((mv new-label events-label)
                    (simpadd0-label stmt.label))
                   ((mv new-stmt events-stmt)
                    (simpadd0-stmt stmt.stmt)))
                (mv (make-stmt-labeled :label new-label
                                       :stmt new-stmt)
                    (append events-label events-stmt)))
     :compound (b* (((mv new-items events-items)
                     (simpadd0-block-item-list stmt.items)))
                 (mv (stmt-compound new-items)
                     events-items))
     :expr (b* (((mv new-expr? events-expr?)
                 (simpadd0-expr-option stmt.expr?)))
             (mv (stmt-expr new-expr?)
                 events-expr?))
     :if (b* (((mv new-test events-test) (simpadd0-expr stmt.test))
              ((mv new-then events-then) (simpadd0-stmt stmt.then)))
           (mv (make-stmt-if :test new-test
                             :then new-then)
               (append events-test events-then)))
     :ifelse (b* (((mv new-test events-test) (simpadd0-expr stmt.test))
                  ((mv new-then events-then) (simpadd0-stmt stmt.then))
                  ((mv new-else events-else) (simpadd0-stmt stmt.else)))
               (mv (make-stmt-ifelse :test new-test
                                     :then new-then
                                     :else new-else)
                   (append events-test events-then events-else)))
     :switch (b* (((mv new-target events-target) (simpadd0-expr stmt.target))
                  ((mv new-body events-body) (simpadd0-stmt stmt.body)))
               (mv (make-stmt-switch :target new-target
                                     :body new-body)
                   (append events-target events-body)))
     :while (b* (((mv new-test events-test) (simpadd0-expr stmt.test))
                 ((mv new-body events-body) (simpadd0-stmt stmt.body)))
              (mv (make-stmt-while :test new-test
                                   :body new-body)
                  (append events-test events-body)))
     :dowhile (b* (((mv new-body events-body) (simpadd0-stmt stmt.body))
                   ((mv new-test events-test) (simpadd0-expr stmt.test)))
                (mv (make-stmt-dowhile :body new-body
                                       :test new-test)
                    (append events-body events-test)))
     :for-expr (b* (((mv new-init events-init)
                     (simpadd0-expr-option stmt.init))
                    ((mv new-test events-test)
                     (simpadd0-expr-option stmt.test))
                    ((mv new-next events-next)
                     (simpadd0-expr-option stmt.next))
                    ((mv new-body events-body)
                     (simpadd0-stmt stmt.body)))
                 (mv (make-stmt-for-expr :init new-init
                                         :test new-test
                                         :next new-next
                                         :body new-body)
                     (append events-init events-test events-next events-body)))
     :for-decl (b* (((mv new-init events-init)
                     (simpadd0-decl stmt.init))
                    ((mv new-test events-test)
                     (simpadd0-expr-option stmt.test))
                    ((mv new-next events-next)
                     (simpadd0-expr-option stmt.next))
                    ((mv new-body events-body)
                     (simpadd0-stmt stmt.body)))
                 (mv (make-stmt-for-decl :init new-init
                                         :test new-test
                                         :next new-next
                                         :body new-body)
                     (append events-init events-test events-next events-body)))
     :for-ambig (prog2$ (impossible) (mv (irr-stmt) nil))
     :goto (mv (stmt-fix stmt) nil)
     :continue (mv (stmt-fix stmt) nil)
     :break (mv (stmt-fix stmt) nil)
     :return (b* (((mv new-expr? events-expr?)
                   (simpadd0-expr-option stmt.expr?)))
               (mv (stmt-return new-expr?)
                   events-expr?))
     :asm (mv (stmt-fix stmt) nil))
    :measure (stmt-count stmt))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-block-item ((item block-itemp))
    :guard (block-item-unambp item)
    :returns (mv (new-item block-itemp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a block item."
    (block-item-case
     item
     :decl (b* (((mv new-item events-item) (simpadd0-decl item.unwrap)))
             (mv (block-item-decl new-item)
                 events-item))
     :stmt (b* (((mv new-item events-item) (simpadd0-stmt item.unwrap)))
             (mv (block-item-stmt new-item)
                 events-item))
     :ambig (prog2$ (impossible) (mv (irr-block-item) nil)))
    :measure (block-item-count item))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define simpadd0-block-item-list ((items block-item-listp))
    :guard (block-item-list-unambp items)
    :returns (mv (new-items block-item-listp)
                 (events pseudo-event-form-listp))
    :parents (simpadd0 simpadd0-exprs/decls/stmts)
    :short "Transform a list of block items."
    (b* (((when (endp items)) (mv nil nil))
         ((mv new-item events-item)
          (simpadd0-block-item (car items)))
         ((mv new-items events-items)
          (simpadd0-block-item-list (cdr items))))
      (mv (cons new-item new-items)
          (append events-item events-items)))
    :measure (block-item-list-count items))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  :hints (("Goal" :in-theory (enable o< o-finp)))

  :verify-guards :after-returns

  ///

  (local (in-theory (enable irr-absdeclor
                            irr-dirabsdeclor)))

  (fty::deffixequiv-mutual simpadd0-exprs/decls/stmts)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (defret-mutual exprs/decls-unambp-of-simpadd0-exprs/decls
    (defret expr-unambp-of-simpadd0-expr
      (expr-unambp new-expr)
      :fn simpadd0-expr)
    (defret expr-list-unambp-of-simpadd0-expr-list
      (expr-list-unambp new-exprs)
      :fn simpadd0-expr-list)
    (defret expr-option-unambp-of-simpadd0-expr-option
      (expr-option-unambp new-expr?)
      :fn simpadd0-expr-option)
    (defret const-expr-unambp-of-simpadd0-const-expr
      (const-expr-unambp new-cexpr)
      :fn simpadd0-const-expr)
    (defret const-expr-option-unambp-of-simpadd0-const-expr-option
      (const-expr-option-unambp new-cexpr?)
      :fn simpadd0-const-expr-option)
    (defret genassoc-unambp-of-simpadd0-genassoc
      (genassoc-unambp new-genassoc)
      :fn simpadd0-genassoc)
    (defret genassoc-list-unambp-of-simpadd0-genassoc-list
      (genassoc-list-unambp new-genassocs)
      :fn simpadd0-genassoc-list)
    (defret member-designor-unambp-of-simpadd0-member-designor
      (member-designor-unambp new-memdes)
      :fn simpadd0-member-designor)
    (defret type-spec-unambp-of-simpadd0-type-spec
      (type-spec-unambp new-tyspec)
      :fn simpadd0-type-spec)
    (defret spec/qual-unambp-of-simpadd0-spec/qual
      (spec/qual-unambp new-specqual)
      :fn simpadd0-spec/qual)
    (defret spec/qual-list-unambp-of-simpadd0-spec/qual-list
      (spec/qual-list-unambp new-specquals)
      :fn simpadd0-spec/qual-list)
    (defret align-spec-unambp-of-simpadd0-align-spec
      (align-spec-unambp new-alignspec)
      :fn simpadd0-align-spec)
    (defret decl-spec-unambp-of-simpadd0-decl-spec
      (decl-spec-unambp new-declspec)
      :fn simpadd0-decl-spec)
    (defret decl-spec-list-unambp-of-simpadd0-decl-spec-list
      (decl-spec-list-unambp new-declspecs)
      :fn simpadd0-decl-spec-list)
    (defret initer-unambp-of-simpadd0-initer
      (initer-unambp new-initer)
      :fn simpadd0-initer)
    (defret initer-option-unambp-of-simpadd0-initer-option
      (initer-option-unambp new-initer?)
      :fn simpadd0-initer-option)
    (defret desiniter-unambp-of-simpadd0-desiniter
      (desiniter-unambp new-desiniter)
      :fn simpadd0-desiniter)
    (defret desiniter-list-unambp-of-simpadd0-desiniter-list
      (desiniter-list-unambp new-desiniters)
      :fn simpadd0-desiniter-list)
    (defret designor-unambp-of-simpadd0-designor
      (designor-unambp new-designor)
      :fn simpadd0-designor)
    (defret designor-list-unambp-of-simpadd0-designor-list
      (designor-list-unambp new-designors)
      :fn simpadd0-designor-list)
    (defret declor-unambp-of-simpadd0-declor
      (declor-unambp new-declor)
      :fn simpadd0-declor)
    (defret declor-option-unambp-of-simpadd0-declor-option
      (declor-option-unambp new-declor?)
      :fn simpadd0-declor-option)
    (defret dirdeclor-unambp-of-simpadd0-dirdeclor
      (dirdeclor-unambp new-dirdeclor)
      :fn simpadd0-dirdeclor)
    (defret absdeclor-unambp-of-simpadd0-absdeclor
      (absdeclor-unambp new-absdeclor)
      :fn simpadd0-absdeclor)
    (defret absdeclor-option-unambp-of-simpadd0-absdeclor-option
      (absdeclor-option-unambp new-absdeclor?)
      :fn simpadd0-absdeclor-option)
    (defret dirabsdeclor-unambp-of-simpadd0-dirabsdeclor
      (dirabsdeclor-unambp new-dirabsdeclor)
      :fn simpadd0-dirabsdeclor)
    (defret dirabsdeclor-option-unambp-of-simpadd0-dirabsdeclor-option
      (dirabsdeclor-option-unambp new-dirabsdeclor?)
      :fn simpadd0-dirabsdeclor-option)
    (defret paramdecl-unambp-of-simpadd0-paramdecl
      (paramdecl-unambp new-paramdecl)
      :fn simpadd0-paramdecl)
    (defret paramdecl-list-unambp-of-simpadd0-paramdecl-list
      (paramdecl-list-unambp new-paramdecls)
      :fn simpadd0-paramdecl-list)
    (defret paramdeclor-unambp-of-simpadd0-paramdeclor
      (paramdeclor-unambp new-paramdeclor)
      :fn simpadd0-paramdeclor)
    (defret tyname-unambp-of-simpadd0-tyname
      (tyname-unambp new-tyname)
      :fn simpadd0-tyname)
    (defret strunispec-unambp-of-simpadd0-strunispec
      (strunispec-unambp new-strunispec)
      :fn simpadd0-strunispec)
    (defret structdecl-unambp-of-simpadd0-structdecl
      (structdecl-unambp new-structdecl)
      :fn simpadd0-structdecl)
    (defret structdecl-list-unambp-of-simpadd0-structdecl-list
      (structdecl-list-unambp new-structdecls)
      :fn simpadd0-structdecl-list)
    (defret structdeclor-unambp-of-simpadd0-structdeclor
      (structdeclor-unambp new-structdeclor)
      :fn simpadd0-structdeclor)
    (defret structdeclor-list-unambp-of-simpadd0-structdeclor-list
      (structdeclor-list-unambp new-structdeclors)
      :fn simpadd0-structdeclor-list)
    (defret enumspec-unambp-of-simpadd0-enumspec
      (enumspec-unambp new-enumspec)
      :fn simpadd0-enumspec)
    (defret enumer-unambp-of-simpadd0-enumer
      (enumer-unambp new-enumer)
      :fn simpadd0-enumer)
    (defret enumer-list-unambp-of-simpadd0-enumer-list
      (enumer-list-unambp new-enumers)
      :fn simpadd0-enumer-list)
    (defret statassert-unambp-of-simpadd0-statassert
      (statassert-unambp new-statassert)
      :fn simpadd0-statassert)
    (defret initdeclor-unambp-of-simpadd0-initdeclor
      (initdeclor-unambp new-initdeclor)
      :fn simpadd0-initdeclor)
    (defret initdeclor-list-unambp-of-simpadd0-initdeclor-list
      (initdeclor-list-unambp new-initdeclors)
      :fn simpadd0-initdeclor-list)
    (defret decl-unambp-of-simpadd0-decl
      (decl-unambp new-decl)
      :fn simpadd0-decl)
    (defret decl-list-unambp-of-simpadd0-decl-list
      (decl-list-unambp new-decls)
      :fn simpadd0-decl-list)
    (defret label-unambp-of-simpadd0-label
      (label-unambp new-label)
      :fn simpadd0-label)
    (defret stmt-unambp-of-simpadd0-stmt
      (stmt-unambp new-stmt)
      :fn simpadd0-stmt)
    (defret block-item-unambp-of-simpadd0-block-item
      (block-item-unambp new-item)
      :fn simpadd0-block-item)
    (defret block-item-list-unambp-of-simpadd0-block-item-list
      (block-item-list-unambp new-items)
      :fn simpadd0-block-item-list)
    :hints (("Goal" :in-theory (enable simpadd0-expr
                                       simpadd0-expr-list
                                       simpadd0-expr-option
                                       simpadd0-const-expr
                                       simpadd0-const-expr-option
                                       simpadd0-genassoc
                                       simpadd0-genassoc-list
                                       simpadd0-type-spec
                                       simpadd0-spec/qual
                                       simpadd0-spec/qual-list
                                       simpadd0-align-spec
                                       simpadd0-decl-spec
                                       simpadd0-decl-spec-list
                                       simpadd0-initer
                                       simpadd0-initer-option
                                       simpadd0-desiniter
                                       simpadd0-desiniter-list
                                       simpadd0-designor
                                       simpadd0-designor-list
                                       simpadd0-declor
                                       simpadd0-declor-option
                                       simpadd0-dirdeclor
                                       simpadd0-absdeclor
                                       simpadd0-absdeclor-option
                                       simpadd0-dirabsdeclor
                                       simpadd0-dirabsdeclor-option
                                       simpadd0-paramdecl
                                       simpadd0-paramdecl-list
                                       simpadd0-paramdeclor
                                       simpadd0-tyname
                                       simpadd0-strunispec
                                       simpadd0-structdecl
                                       simpadd0-structdecl-list
                                       simpadd0-structdeclor
                                       simpadd0-structdeclor-list
                                       simpadd0-enumspec
                                       simpadd0-enumer
                                       simpadd0-enumer-list
                                       simpadd0-statassert
                                       simpadd0-initdeclor
                                       simpadd0-initdeclor-list
                                       simpadd0-decl
                                       simpadd0-decl-list
                                       simpadd0-label
                                       simpadd0-stmt
                                       simpadd0-block-item
                                       simpadd0-block-item-list
                                       irr-expr
                                       irr-const-expr
                                       irr-align-spec
                                       irr-dirabsdeclor
                                       irr-paramdeclor
                                       irr-type-spec
                                       irr-stmt
                                       irr-block-item)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-fundef ((fundef fundefp))
  :guard (fundef-unambp fundef)
  :returns (mv (new-fundef fundefp)
               (events pseudo-event-form-listp))
  :short "Transform a function definition."
  (b* (((fundef fundef) fundef)
       ((mv new-spec events-spec) (simpadd0-decl-spec-list fundef.spec))
       ((mv new-declor events-declor) (simpadd0-declor fundef.declor))
       ((mv new-decls events-decls) (simpadd0-decl-list fundef.decls))
       ((mv new-body events-body) (simpadd0-stmt fundef.body)))
    (mv (make-fundef :extension fundef.extension
                     :spec new-spec
                     :declor new-declor
                     :asm? fundef.asm?
                     :attribs fundef.attribs
                     :decls new-decls
                     :body new-body)
        (append events-spec
                events-declor
                events-decls
                events-body)))
  :hooks (:fix)

  ///

  (defret fundef-unambp-of-simpadd0-fundef
    (fundef-unambp new-fundef)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-extdecl ((extdecl extdeclp))
  :guard (extdecl-unambp extdecl)
  :returns (mv (new-extdecl extdeclp)
               (events pseudo-event-form-listp))
  :short "Transform an external declaration."
  (extdecl-case
   extdecl
   :fundef (b* (((mv new-fundef events-fundef)
                 (simpadd0-fundef extdecl.unwrap)))
             (mv (extdecl-fundef new-fundef)
                 events-fundef))
   :decl (b* (((mv new-decl events-decl)
               (simpadd0-decl extdecl.unwrap)))
           (mv (extdecl-decl new-decl)
               events-decl))
   :empty (mv (extdecl-empty) nil)
   :asm (mv (extdecl-fix extdecl) nil))
  :hooks (:fix)

  ///

  (defret extdecl-unambp-of-simpadd0-extdecl
    (extdecl-unambp new-extdecl)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-extdecl-list ((extdecls extdecl-listp))
  :guard (extdecl-list-unambp extdecls)
  :returns (mv (new-extdecls extdecl-listp)
               (events pseudo-event-form-listp))
  :short "Transform a list of external declarations."
  (b* (((when (endp extdecls)) (mv nil nil))
       ((mv new-edecl events-edecl) (simpadd0-extdecl (car extdecls)))
       ((mv new-edecls events-edecls) (simpadd0-extdecl-list (cdr extdecls))))
    (mv (cons new-edecl new-edecls)
        (append events-edecl events-edecls)))
  :hooks (:fix)

  ///

  (defret extdecl-list-unambp-of-simpadd0-extdecl-list
    (extdecl-list-unambp new-extdecls)
    :hints (("Goal" :induct t))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-transunit ((tunit transunitp))
  :guard (transunit-unambp tunit)
  :returns (mv (new-tunit transunitp)
               (events pseudo-event-form-listp))
  :short "Transform a translation unit."
  (b* (((transunit tunit) tunit)
       ((mv new-decls events-decls) (simpadd0-extdecl-list tunit.decls)))
    (mv  (make-transunit :decls new-decls
                         :info tunit.info)
         events-decls))
  :hooks (:fix)

  ///

  (defret transunit-unambp-of-simpadd0-transunit
    (transunit-unambp new-tunit)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-filepath ((path filepathp))
  :returns (new-path filepathp)
  :short "Transform a file path."
  :long
  (xdoc::topstring
   (xdoc::p
    "We only support file paths that consist of strings.
     We transform the path by interposing @('.simpadd0')
     just before the rightmost dot of the file extension, if any;
     if there is no file extension, we just add @('.simpadd0') at the end.
     So for instance a path @('path/to/file.c')
     becomes @('path/to/file.simpadd0.c').")
   (xdoc::p
    "Note that this kind of file path transformations
     supports chaining of transformations,
     e.g. @('path/to/file.xform1.xform2.xform3.c')."))
  (b* ((string (filepath->unwrap path))
       ((unless (stringp string))
        (raise "Misusage error: file path ~x0 is not a string." string)
        (filepath "irrelevant"))
       (chars (str::explode string))
       (dot-pos-in-rev (index-of #\. (rev chars)))
       ((when (not dot-pos-in-rev))
        (filepath (str::implode (append chars
                                        (str::explode ".simpadd0")))))
       (last-dot-pos (- (len chars) dot-pos-in-rev))
       (new-chars (append (take last-dot-pos chars)
                          (str::explode "simpadd0.")
                          (nthcdr last-dot-pos chars)))
       (new-string (str::implode new-chars)))
    (filepath new-string))
  :guard-hints
  (("Goal"
    :use (:instance acl2::index-of-<-len
                    (k #\.)
                    (x (rev (str::explode (filepath->unwrap path)))))
    :in-theory (e/d (nfix) (acl2::index-of-<-len))))
  :hooks (:fix)
  :prepwork ((local (include-book "arithmetic-3/top" :dir :system))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-filepath-transunit-map ((map filepath-transunit-mapp))
  :guard (filepath-transunit-map-unambp map)
  :returns (mv (new-map filepath-transunit-mapp
                        :hyp (filepath-transunit-mapp map))
               (events pseudo-event-form-listp))
  :short "Transform a map from file paths to translation units."
  :long
  (xdoc::topstring
   (xdoc::p
    "We transform both the file paths and the translation units."))
  (b* (((when (omap::emptyp map)) (mv nil nil))
       ((mv path tunit) (omap::head map))
       (new-path (simpadd0-filepath path))
       ((mv new-tunit events-tunit) (simpadd0-transunit tunit))
       ((mv new-map events-map)
        (simpadd0-filepath-transunit-map (omap::tail map))))
    (mv (omap::update new-path new-tunit new-map)
        (append events-tunit events-map)))
  :verify-guards :after-returns

  ///

  (defret filepath-transunit-map-unambp-of-simpadd-filepath-transunit-map
    (filepath-transunit-map-unambp new-map)
    :hyp (filepath-transunit-mapp map)
    :hints (("Goal" :induct t))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-transunit-ensemble ((tunits transunit-ensemblep))
  :guard (transunit-ensemble-unambp tunits)
  :returns (mv (new-tunits transunit-ensemblep)
               (events pseudo-event-form-listp))
  :short "Transform a translation unit ensemble."
  (b* (((transunit-ensemble tunits) tunits)
       ((mv new-map events-map)
        (simpadd0-filepath-transunit-map tunits.unwrap)))
    (mv (transunit-ensemble new-map)
        events-map))
  :hooks (:fix)

  ///

  (defret transunit-ensemble-unambp-of-simpadd0-transunit-ensemble
    (transunit-ensemble-unambp new-tunits)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-gen-proof-for-fun ((term-old "A term.")
                                    (term-new "A term.")
                                    (fun identp))
  :returns (event pseudo-event-formp)
  :short "Generate equivalence theorem for a function."
  :long
  (xdoc::topstring
   (xdoc::p
    "The theorem just says that executing the the function,
     in the old and new translation unit,
     returns the same result.
     We use an arbitrary 1000 as the limit value.
     Clearly, all of this is very simple and ad hoc."))
  (b* ((string (ident->unwrap fun))
       ((unless (stringp string))
        (raise "Misusage error: function name ~x0 is not a string." string)
        '(_))
       (thm-name (packn-pos (list string '-equivalence) 'c2c))
       (event
        `(defruled ,thm-name
           (equal (c::exec-fun (c::ident ,string)
                               nil
                               compst
                               (c::init-fun-env
                                (mv-nth 1 (c$::ldm-transunit ,term-old)))
                               1000)
                  (c::exec-fun (c::ident ,string)
                               nil
                               compst
                               (c::init-fun-env
                                (mv-nth 1 (c$::ldm-transunit ,term-new)))
                               1000))
           :enable (c::atc-all-rules
                    c::fun-env-lookup
                    omap::assoc
                    c::exec-binary-strict-pure-when-add-alt)
           :disable ((:e c::ident)))))
    event)
  :guard-hints (("Goal" :in-theory (enable atom-listp))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-gen-proofs-for-transunit ((term-old "A term.")
                                           (term-new "A term.")
                                           (tunit transunitp))
  :returns (events pseudo-event-form-listp)
  :short "Generate equivalence theorems
          for all the functions in a translation unit."
  (simpadd0-gen-proofs-for-transunit-loop term-old
                                          term-new
                                          (transunit->decls tunit))
  :prepwork
  ((define simpadd0-gen-proofs-for-transunit-loop ((term-old "A term.")
                                                   (term-new "A term.")
                                                   (extdecls extdecl-listp))
     :returns (events pseudo-event-form-listp)
     :parents nil
     (b* (((when (endp extdecls)) nil)
          (extdecl (car extdecls))
          ((unless (extdecl-case extdecl :fundef))
           (simpadd0-gen-proofs-for-transunit-loop term-old
                                                   term-new
                                                   (cdr extdecls)))
          (fundef (extdecl-fundef->unwrap extdecl))
          (declor (fundef->declor fundef))
          (dirdeclor (declor->direct declor))
          ((unless (member-eq (dirdeclor-kind dirdeclor)
                              '(:function-params :function-names)))
           (raise "Internal error: ~
                   direct declarator of function definition ~x0 ~
                   is not a function declarator."
                  fundef))
          ((unless (cond
                    ((dirdeclor-case dirdeclor :function-params)
                     (endp (dirdeclor-function-params->params dirdeclor)))
                    ((dirdeclor-case dirdeclor :function-names)
                     (endp (dirdeclor-function-names->names dirdeclor)))))
           (raise "Proof generation is currently supported ~
                   only for functions with no parameters, ~
                   but the function definition ~x0 has parameters."
                  fundef))
          (fun (declor->ident declor))
          (event (simpadd0-gen-proof-for-fun term-old
                                             term-new
                                             fun))
          (events (simpadd0-gen-proofs-for-transunit-loop term-old
                                                          term-new
                                                          (cdr extdecls))))
       (cons event events)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-gen-proofs-for-transunit-ensemble
  ((const-old symbolp)
   (const-new symbolp)
   (tunits-old transunit-ensemblep)
   (tunits-new transunit-ensemblep))
  :returns (events pseudo-event-form-listp)
  :short "Generate equivalence theorems for all functions in
          a translation unit ensemble."
  (simpadd0-gen-proofs-for-transunit-ensemble-loop
   const-old
   const-new
   (transunit-ensemble->unwrap tunits-old)
   (transunit-ensemble->unwrap tunits-new))
  :prepwork
  ((define simpadd0-gen-proofs-for-transunit-ensemble-loop
     ((const-old symbolp)
      (const-new symbolp)
      (tunitmap-old filepath-transunit-mapp)
      (tunitmap-new filepath-transunit-mapp))
     :returns (events pseudo-event-form-listp)
     :parents nil
     (b* (((when (omap::emptyp tunitmap-old)) nil)
          ((when (omap::emptyp tunitmap-new))
           (raise "Internal error: extra translation units ~x0." tunitmap-new))
          ((mv path-old tunit) (omap::head tunitmap-old))
          ((mv path-new &) (omap::head tunitmap-new))
          (term-old `(omap::lookup
                      ',path-old
                      (transunit-ensemble->unwrap ,const-old)))
          (term-new `(omap::lookup
                      ',path-new
                      (transunit-ensemble->unwrap ,const-new)))
          (events (simpadd0-gen-proofs-for-transunit term-old
                                                     term-new
                                                     tunit))
          (more-events (simpadd0-gen-proofs-for-transunit-ensemble-loop
                        const-old
                        const-new
                        (omap::tail tunitmap-old)
                        (omap::tail tunitmap-new))))
       (append events more-events)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-gen-everything ((tunits-old transunit-ensemblep)
                                 (const-old symbolp)
                                 (const-new symbolp)
                                 (proofs booleanp))
  :guard (and (transunit-ensemble-unambp tunits-old)
              (transunit-ensemble-annop tunits-old))
  :returns (mv erp (event pseudo-event-formp))
  :short "Event expansion of the transformation."
  (b* (((reterr) '(_))
       ((mv tunits-new &) (simpadd0-transunit-ensemble tunits-old))
       ((mv erp &) (if (not proofs)
                       (retok :irrelevant)
                     (c$::ldm-transunit-ensemble tunits-old)))
       ((when erp)
        (reterr (msg "The old translation unit ensemble ~x0 ~
                      is not within the subset of C ~
                      covered by our formal semantics. ~
                      ~@1 ~
                      Thus, proofs cannot be generated: ~
                      re-run the transformation with :PROOFS NIL."
                     tunits-old erp)))
       ((mv erp &) (if (not proofs)
                       (retok :irrelevant)
                     (c$::ldm-transunit-ensemble tunits-new)))
       ((when erp)
        (reterr (msg "The new translation unit ensemble ~x0 ~
                      is not within the subset of C ~
                      covered by our formal semantics. ~
                      ~@1 ~
                      Thus, proofs cannot be generated: ~
                      re-run the transformation with :PROOFS NIL."
                     tunits-new erp)))
       (thm-events (and proofs
                        (simpadd0-gen-proofs-for-transunit-ensemble
                         const-old const-new tunits-old tunits-new)))
       (const-event `(defconst ,const-new ',tunits-new)))
    (retok `(encapsulate () ,const-event ,@thm-events))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-process-inputs-and-gen-everything (const-old
                                                    const-new
                                                    proofs
                                                    (wrld plist-worldp))
  :returns (mv erp (event pseudo-event-formp))
  :parents (simpadd0-implementation)
  :short "Process the inputs and generate the events."
  (b* (((reterr) '(_))
       ((erp tunits-old const-old const-new proofs)
        (simpadd0-process-inputs const-old const-new proofs wrld)))
    (simpadd0-gen-everything tunits-old const-old const-new proofs)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define simpadd0-fn (const-old const-new proofs (ctx ctxp) state)
  :returns (mv erp (event pseudo-event-formp) state)
  :parents (simpadd0-implementation)
  :short "Event expansion of @(tsee simpadd0)."
  (b* (((mv erp event)
        (simpadd0-process-inputs-and-gen-everything const-old
                                                    const-new
                                                    proofs
                                                    (w state)))
       ((when erp) (er-soft+ ctx t '(_) "~@0" erp)))
    (value event)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsection simpadd0-macro-definition
  :parents (simpadd0-implementation)
  :short "Definition of the @(tsee simpadd0) macro."
  (defmacro simpadd0 (const-old const-new &key proofs)
    `(make-event
      (simpadd0-fn ',const-old ',const-new ,proofs 'simpadd0 state))))
