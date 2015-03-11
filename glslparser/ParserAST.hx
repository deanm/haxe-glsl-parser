package glslparser;

//#! also add node location (+length)? (Computed from the subnode's positions)
//Define leaf type that is a proxy for a token?
//Perhaps some sort of isGlobal bool on declarations to account for external_declaration

import glslparser.Parser.EMinorType;
import glslparser.Parser.MinorType;
import glslparser.Tokenizer.Token;
import glslparser.Tokenizer.TokenType;


//AST definitions
//Loosely following Mozilla Parser AST API 
//And guided by Mesa Compiler AST
//http://people.freedesktop.org/~chadversary/mesa/doxygen/kevin-rogovin/d7/d26/group__AST.html

//Should statement have node? Shouldn't it _be_ the node?
//Shouldn't IterationStatement extend Statement?
//Review use and meaning of Expression
//All tokens should be converted to EnumValues or Nodes?
//Should TokenType be allow? If everything is enum, how can we easily compare equivalent enums from two sets?
//define constant expression where necessary 
//Bring MinorType definitions into this class
//Separate  ParseCore in preparation for Preprocessor parser

@:publicFields
class Node{
	var nodeTypeName:String;
	function new(){
		this.nodeTypeName = Type.getClassName(Type.getClass(this)).split('.').pop();
		trace(' --- New node: '+ this.nodeTypeName +' -> '+ debugString());
	}

	function debugString(){//#!
		var m:MinorType = this;
		return Std.string(m);
	}

	// public function toGLSL():String return ''; //#!
}

class TypeSpecifier extends Node{
	var typeName:String;
	var typeClass:TypeClass;
	var qualifier:TypeQualifier;
	var precision:PrecisionQualifier;
	function new(typeClass:TypeClass, typeName:String, ?qualifier:TypeQualifier, ?precision:PrecisionQualifier){
		this.typeName = typeName;
		this.typeClass = typeClass;
		this.qualifier = qualifier;
		this.precision = precision;
		super();
	}
}

class StructSpecifier extends TypeSpecifier{
	var structDeclarations:StructDeclarationList;
	function new(name:String, structDeclarations:StructDeclarationList){
		this.structDeclarations = structDeclarations;
		super(STRUCT, name);
	}
}

typedef StructDeclarationList = Array<StructDeclaration>;


class StructDeclaration extends Node{//#! extends Declaration?
	var typeSpecifier:TypeSpecifier;
	var declarators:StructDeclaratorList;
	function new(typeSpecifier:TypeSpecifier, declarators:StructDeclaratorList){
		this.typeSpecifier = typeSpecifier;
		this.declarators = declarators;
		super();
	}
}

typedef StructDeclaratorList = Array<StructDeclarator>;

class StructDeclarator extends Node{
	var name:String;
	function new(name:String){
		this.name = name;
		super();
	}
}

class  StructArrayDeclarator extends StructDeclarator{
	var arraySizeExpression:Expression;
	function new(name:String, arraySizeExpression:Expression){
		this.arraySizeExpression = arraySizeExpression;
		super(name);
	}
}

//Expressions
class Expression extends Node{
	var parenWrap:Bool;
}

class Identifier extends Expression{
	var name:String;
	function new(name:String) {
		this.name = name;
		super();
	}
}

class Literal<T> extends Expression{
	var value:T;
	var raw:String;
	function new(value:T, raw:String){
		this.value = value;
		this.raw = raw;
		super();
	}
}

class BinaryExpression extends Expression{
	var op:BinaryOperator;
	var left:Expression;
	var right:Expression;
	function new(op:BinaryOperator, left:Expression, right:Expression){
		this.op = op;
		this.left = left;
		this.right = right;
		super();
	}
}

class LogicalExpression extends BinaryExpression{}

class UnaryExpression extends Expression{
	var op:UnaryOperator;
	var arg:Node;//#! should be expression?
	var isPrefix:Bool;
	function new(op:UnaryOperator, arg:Node, isPrefix:Bool){
		this.op = op;
		this.arg = arg;
		this.isPrefix = isPrefix;
		super();
	}
}

class ConditionalExpression extends Expression{
	var test:Expression;
	var consequent:Expression;
	var alternate:Expression;
	function new(test:Expression, consequent:Expression, alternate:Expression){
		this.test = test;
		this.consequent = consequent;
		this.alternate = alternate;
		super();
	}
}

class AssignmentExpression extends Expression{
	var op:AssignmentOperator;
	var left:Expression;
	var right:Expression;
	function new(op:AssignmentOperator, left:Expression, right:Expression){
		this.op = op;
		this.left = left;
		this.right = right;
		super();
	}
}

class FieldSelectionExpression extends Expression{
	var left:Expression;
	var field:Identifier;
	function new(left:Expression, field:Identifier){
		this.left = left;
		this.field = field;
		super();
	}
}

class ArrayElementSelectionExpression extends Expression{
	var left:Expression;
	var arrayIndexExpression:Expression;
	function new(left:Expression, arrayIndexExpression:Expression){
		this.left = left;
		this.arrayIndexExpression = arrayIndexExpression;
		super();	
	}
}

class FunctionCall extends Expression{
	var name:String;
	var parameters:Array<Expression>;
	function new(name, ?parameters){
		this.name = name;
		this.parameters = parameters != null ? parameters : [];
		super();
	}
}

class FunctionHeader extends Expression{
	var name:String;
	var returnType:TypeSpecifier;
	var parameters:Array<ParameterDeclaration>;
	function new(name:String, returnType:TypeSpecifier, ?parameters:Array<ParameterDeclaration>){
		this.name = name;
		this.returnType = returnType;
		this.parameters = parameters != null ? parameters : [];
		super();
	}
}


//Declarations
class Declaration extends Expression{
	var global:Bool;
}

typedef TranslationUnit = Array<Declaration>;

class PrecisionDeclaration extends Declaration{
	var precision:PrecisionQualifier;
	var typeSpecifier:TypeSpecifier;
	function new(precision:PrecisionQualifier, typeSpecifier:TypeSpecifier){
		this.precision = precision;
		this.typeSpecifier = typeSpecifier;
		super();
	}
}

class VariableDeclaration extends Declaration{
	var typeSpecifier:TypeSpecifier;
	var declarators:Array<Declarator>;
	function new(typeSpecifier:TypeSpecifier, declarators:Array<Declarator>){
		this.typeSpecifier = typeSpecifier;
		this.declarators = declarators;
		super();
	}
}

class Declarator extends Node{
	var name:String;
	var invariant:Bool;
	var initializer:Node;
	function new(name:String, ?initializer:Node, invariant:Bool = false){
		this.name = name;
		this.initializer = initializer;
		this.invariant = invariant;
		super();
	}
}

class ArrayDeclarator extends Declarator{
	var arraySizeExpression:Node;
	function new(name:String, arraySizeExpression:Node){
		this.arraySizeExpression = arraySizeExpression;
		super(name, null, false);
	}
}

class ParameterDeclaration extends Declaration{
	var name:String;
	var parameterQualifier:ParameterQualifier;
	var typeQualifier:TypeQualifier;
	var typeSpecifier:TypeSpecifier;
	var arraySizeExpression:Node;
	function new(name:String, typeSpecifier:TypeSpecifier, ?parameterQualifier:ParameterQualifier, ?typeQualifier:TypeQualifier, ?arraySizeExpression:Node){
		this.name = name;
		this.typeSpecifier = typeSpecifier;
		this.parameterQualifier = parameterQualifier;
		this.typeQualifier = typeQualifier;
		this.arraySizeExpression = arraySizeExpression;
		super();
	}
}

class FunctionDefinition extends Declaration{
	var header:FunctionHeader;
	var body:CompoundStatement;
	function new(header:FunctionHeader, body:CompoundStatement){
		this.header = header;
		this.body = body;
		super();
	}
}

class FunctionPrototype extends Declaration{
	var header:FunctionHeader;
	function new(header:FunctionHeader){
		this.header = header;
		super();
	}
}


//Statements
class Statement extends Expression{
	var node:Node;
	var newScope:Bool;
	function new(node:Node, newScope:Bool){
		this.node = node;
		this.newScope = newScope;
		super();
	}
}

typedef StatementList = Array<Statement>;

class CompoundStatement extends Node{
	var statementList:StatementList;
	var newScope:Bool;
	function new(statementList:StatementList, ?newScope:Bool){
		this.statementList = statementList;
		this.newScope = newScope;
		super();
	}
}

class IterationStatement extends Node{
	var body:Statement;
	function new(body:Statement){
		this.body = body;
		super();
	}
}

class WhileStatement extends IterationStatement{
	var test:Expression;
	function new(test:Expression, body:Statement){
		this.test = test;
		super(body);
	}
}

class DoWhileStatement extends IterationStatement{
	var test:Expression;
	function new(test:Expression, body:Statement){
		this.test = test;
		super(body);
	}
}

class ForStatement extends IterationStatement{
	var initStatement:Statement;
	var restStatement:Statement;
	function new(initStatement:Statement, restStatement:Statement, body:Statement){
		this.initStatement = initStatement;
		this.restStatement = restStatement;
		super(body);
	}
}

class JumpStatement extends Node{
	var mode:JumpMode;
	function new(mode:JumpMode){
		this.mode = mode;
		super();
	}
}

class ReturnStatement extends JumpStatement{
	var returnValue:Expression;
	function new(returnValue:Expression){
		this.returnValue = returnValue;
		super(RETURN);
	}
}

//Base Types #! look into enum abstracts
typedef BinaryOperator = TokenType;
typedef UnaryOperator = TokenType;
typedef AssignmentOperator = TokenType;
typedef PrecisionQualifier = TokenType;

typedef JumpMode = TokenType;

typedef TypeClass = TokenType;// basic types + STRUCT + TYPE_NAME
typedef ConstructableType = TokenType;// IDENTIFIER + basic types + TYPE_NAME

enum ParameterQualifier{
	IN;
	OUT;
	INOUT;
}

enum TypeQualifier{
	CONST;
	ATTRIBUTE;
	VARYING;
	INVARIANT_VARYING;
	UNIFORM;
}

@:access(glslparser.Parser)
class ParserAST{
	static public var root:Node;

	static var i(get, null):Int;
	static var stack(get, null):Parser.Stack;
	static var ruleno;


	static public function createNode(ruleno:Int):MinorType{
		ParserAST.ruleno = ruleno; //set class ruleno so it can be accessed by other functions

		switch(ruleno){
			case 0: root = n(1); return s(1); //root ::= translation_unit
			case 1: return new Identifier(t(1).data);//variable_identifier ::= IDENTIFIER
			case 2: return s(1); //primary_expression ::= variable_identifier
			case 3: return new Literal<Int>(Std.parseInt(t(1).data), t(1).data);//primary_expression ::= INTCONSTANT
			case 4: return new Literal<Float>(Std.parseFloat(t(1).data), t(1).data); //primary_expression ::= FLOATCONSTANT
			case 5: return new Literal<Bool>(t(1).data == 'true', t(1).data); //primary_expression ::= BOOLCONSTANT
			case 6: e(2).parenWrap = true; return s(2); //primary_expression ::= LEFT_PAREN expression RIGHT_PAREN
			case 7: return s(1); //postfix_expression ::= primary_expression
			case 8: return new ArrayElementSelectionExpression(e(1), e(3)); //??? //postfix_expression ::= postfix_expression LEFT_BRACKET integer_expression RIGHT_BRACKET
			case 9: return s(1); //postfix_expression ::= function_call
			case 10: return new FieldSelectionExpression(e(1), new Identifier(t(3).data)); //postfix_expression ::= postfix_expression DOT FIELD_SELECTION
			case 11: return new UnaryExpression(t(2).type, n(1), false); //postfix_expression ::= postfix_expression INC_OP
			case 12: return new UnaryExpression(t(2).type, n(1), false); //postfix_expression ::= postfix_expression DEC_OP
			case 13: return s(1); //integer_expression ::= expression
			case 14: return s(1); //function_call ::= function_call_generic
			case 15: return s(1); //function_call_generic ::= function_call_header_with_parameters RIGHT_PAREN
			case 16: return s(1); //function_call_generic ::= function_call_header_no_parameters RIGHT_PAREN
			case 17: return s(1); //function_call_header_no_parameters ::= function_call_header VOID
			case 18: return s(1); //function_call_header_no_parameters ::= function_call_header
			case 19: cast(n(1), FunctionCall).parameters.push(cast n(2)); return s(1); //function_call_header_with_parameters ::= function_call_header assignment_expression
			case 20: cast(n(1), FunctionCall).parameters.push(cast n(3)); return s(1); //function_call_header_with_parameters ::= function_call_header_with_parameters COMMA assignment_expression
			case 21: return s(1); //function_call_header ::= function_identifier LEFT_PAREN
			case 22: return new FunctionCall(t(1).data); //function_identifier ::= constructor_identifier
			case 23: return new FunctionCall(t(1).data); //function_identifier ::= IDENTIFIER
			case 24: return s(1); //constructor_identifier ::= FLOAT
			case 25: return s(1); //constructor_identifier ::= INT
			case 26: return s(1); //constructor_identifier ::= BOOL
			case 27: return s(1); //constructor_identifier ::= VEC2
			case 28: return s(1); //constructor_identifier ::= VEC3
			case 29: return s(1); //constructor_identifier ::= VEC4
			case 30: return s(1); //constructor_identifier ::= BVEC2
			case 31: return s(1); //constructor_identifier ::= BVEC3
			case 32: return s(1); //constructor_identifier ::= BVEC4
			case 33: return s(1); //constructor_identifier ::= IVEC2
			case 34: return s(1); //constructor_identifier ::= IVEC3
			case 35: return s(1); //constructor_identifier ::= IVEC4
			case 36: return s(1); //constructor_identifier ::= MAT2
			case 37: return s(1); //constructor_identifier ::= MAT3
			case 38: return s(1); //constructor_identifier ::= MAT4
			case 39: return s(1); //constructor_identifier ::= TYPE_NAME
			case 40: return s(1); //unary_expression ::= postfix_expression
			case 41: return new UnaryExpression(t(1).type, n(2), true); //unary_expression ::= INC_OP unary_expression
			case 42: return new UnaryExpression(t(1).type, n(2), true); //unary_expression ::= DEC_OP unary_expression
			case 43: return new UnaryExpression(t(1).type, n(2), true); //unary_expression ::= unary_operator unary_expression
			case 44: return s(1); //unary_operator ::= PLUS
			case 45: return s(1); //unary_operator ::= DASH
			case 46: return s(1); //unary_operator ::= BANG
			case 47: return s(1); //unary_operator ::= TILDE
			case 48: return s(1); //multiplicative_expression ::= unary_expression
			case 49: return new BinaryExpression(t(2).type, e(1), e(3)); //multiplicative_expression ::= multiplicative_expression STAR unary_expression
			case 50: return new BinaryExpression(t(2).type, e(1), e(3)); //multiplicative_expression ::= multiplicative_expression SLASH unary_expression
			case 51: return new BinaryExpression(t(2).type, e(1), e(3)); //multiplicative_expression ::= multiplicative_expression PERCENT unary_expression
			case 52: return s(1); //additive_expression ::= multiplicative_expression
			case 53: return new BinaryExpression(t(2).type, e(1), e(3)); //additive_expression ::= additive_expression PLUS multiplicative_expression
			case 54: return new BinaryExpression(t(2).type, e(1), e(3)); //additive_expression ::= additive_expression DASH multiplicative_expression
			case 55: return s(1); //shift_expression ::= additive_expression
			case 56: return new BinaryExpression(t(2).type, cast n(1), cast n(3)); //shift_expression ::= shift_expression LEFT_OP additive_expression
			case 57: return new BinaryExpression(t(2).type, cast n(1), cast n(3)); //shift_expression ::= shift_expression RIGHT_OP additive_expression
			case 58: return s(1); //relational_expression ::= shift_expression
			case 59: return new BinaryExpression(t(2).type, cast n(1), cast n(3)); //relational_expression ::= relational_expression LEFT_ANGLE shift_expression
			case 60: return new BinaryExpression(t(2).type, cast n(1), cast n(3)); //relational_expression ::= relational_expression RIGHT_ANGLE shift_expression
			case 61: return new BinaryExpression(t(2).type, cast n(1), cast n(3)); //relational_expression ::= relational_expression LE_OP shift_expression
			case 62: return new BinaryExpression(t(2).type, cast n(1), cast n(3)); //relational_expression ::= relational_expression GE_OP shift_expression
			case 63: return s(1); //equality_expression ::= relational_expression
			case 64: return new BinaryExpression(t(2).type, cast n(1), cast n(3)); //equality_expression ::= equality_expression EQ_OP relational_expression
			case 65: return new BinaryExpression(t(2).type, cast n(1), cast n(3)); //equality_expression ::= equality_expression NE_OP relational_expression
			case 66: return s(1); //and_expression ::= equality_expression
			case 67: return new BinaryExpression(t(2).type, cast n(1), cast n(3)); //and_expression ::= and_expression AMPERSAND equality_expression
			case 68: return s(1); //exclusive_or_expression ::= and_expression
			case 69: return new LogicalExpression(t(2).type, cast n(1), cast n(3)); //exclusive_or_expression ::= exclusive_or_expression CARET and_expression
			case 70: return s(1); //inclusive_or_expression ::= exclusive_or_expression
			case 71: return new LogicalExpression(t(2).type, cast n(1), cast n(3)); //inclusive_or_expression ::= inclusive_or_expression VERTICAL_BAR exclusive_or_expression
			case 72: return s(1); //logical_and_expression ::= inclusive_or_expression
			case 73: return new LogicalExpression(t(2).type, cast n(1), cast n(3)); //logical_and_expression ::= logical_and_expression AND_OP inclusive_or_expression
			case 74: return s(1); //logical_xor_expression ::= logical_and_expression
			case 75: return new LogicalExpression(t(2).type, cast n(1), cast n(3)); //logical_xor_expression ::= logical_xor_expression XOR_OP logical_and_expression
			case 76: return s(1); //logical_or_expression ::= logical_xor_expression
			case 77: return new LogicalExpression(t(2).type, cast n(1), cast n(3)); //logical_or_expression ::= logical_or_expression OR_OP logical_xor_expression
			case 78: return s(1); //conditional_expression ::= logical_or_expression
			case 79: return new ConditionalExpression(cast n(1), cast n(2), cast n(3)); //conditional_expression ::= logical_or_expression QUESTION expression COLON assignment_expression
			case 80: return s(1); //assignment_expression ::= conditional_expression
			case 81: return new AssignmentExpression(t(2).type, cast n(1), cast n(3)); //assignment_expression ::= unary_expression assignment_operator assignment_expression
			case 82: return s(1); //assignment_operator ::= EQUAL
			case 83: return s(1); //assignment_operator ::= MUL_ASSIGN
			case 84: return s(1); //assignment_operator ::= DIV_ASSIGN
			case 85: return s(1); //assignment_operator ::= MOD_ASSIGN
			case 86: return s(1); //assignment_operator ::= ADD_ASSIGN
			case 87: return s(1); //assignment_operator ::= SUB_ASSIGN
			case 88: return s(1); //assignment_operator ::= LEFT_ASSIGN
			case 89: return s(1); //assignment_operator ::= RIGHT_ASSIGN
			case 90: return s(1); //assignment_operator ::= AND_ASSIGN
			case 91: return s(1); //assignment_operator ::= XOR_ASSIGN
			case 92: return s(1); //assignment_operator ::= OR_ASSIGN
			case 93: return s(1); //expression ::= assignment_expression
			case 94: //??? ExpressionList? SequenceExpression? CompoundExpression //expression ::= expression COMMA assignment_expression
			case 95: return s(1); //constant_expression ::= conditional_expression
			case 96: return new FunctionPrototype(cast s(1)); //declaration ::= function_prototype SEMICOLON
			case 97: return s(1); //declaration ::= init_declarator_list SEMICOLON
			case 98: return new PrecisionDeclaration(t(2).type, cast n(3)); //declaration ::= PRECISION precision_qualifier type_specifier_no_prec SEMICOLON
			case 99: return s(1); //function_prototype ::= function_declarator RIGHT_PAREN
			case 100: return s(1); //function_declarator ::= function_header
			case 101: return s(1); //function_declarator ::= function_header_with_parameters
			case 102: var fh = cast(n(1), FunctionHeader); //function_header_with_parameters ::= function_header parameter_declaration
						fh.parameters.push(cast n(2));
						return fh;
			case 103: var fh = cast(n(1), FunctionHeader); //function_header_with_parameters ::= function_header_with_parameters COMMA parameter_declaration
						fh.parameters.push(cast n(3));
						return fh; 
			case 104: return new FunctionHeader(t(2).data, cast n(1)); //function_header ::= fully_specified_type IDENTIFIER LEFT_PAREN
			case 105: return new ParameterDeclaration(t(2).data, cast n(1)); //parameter_declarator ::= type_specifier IDENTIFIER
			case 106: return new ParameterDeclaration(t(2).data, cast n(1), null, null, cast e(3)); //parameter_declarator ::= type_specifier IDENTIFIER LEFT_BRACKET constant_expression RIGHT_BRACKET
			case 107: var pd = cast(n(3), ParameterDeclaration); //parameter_declaration ::= type_qualifier parameter_qualifier parameter_declarator
						pd.typeQualifier = cast ev(1);
						pd.parameterQualifier = cast ev(2);
						return pd;
			case 108: var pd = cast(n(2), ParameterDeclaration); //parameter_declaration ::= parameter_qualifier parameter_declarator
						pd.parameterQualifier = cast ev(1);
						return pd;
			case 109: var pd = cast(n(3), ParameterDeclaration); //parameter_declaration ::= type_qualifier parameter_qualifier parameter_type_specifier
						pd.typeQualifier = cast ev(1);
						pd.parameterQualifier = cast ev(2);
						return pd;
			case 110: var pd = cast(n(2), ParameterDeclaration); //parameter_declaration ::= parameter_qualifier parameter_type_specifier
						pd.parameterQualifier = cast ev(1);
						return pd;
			case 111: return null; //parameter_qualifier ::=
			case 112: return ParameterQualifier.IN;//parameter_qualifier ::= IN
			case 113: return ParameterQualifier.OUT;//parameter_qualifier ::= OUT
			case 114: return ParameterQualifier.INOUT;//parameter_qualifier ::= INOUT
			case 115: return new ParameterDeclaration(null, cast n(1)); //parameter_type_specifier ::= type_specifier
			case 116: return new ParameterDeclaration(null, cast n(1), null, null, cast e(3));//parameter_type_specifier ::= type_specifier LEFT_BRACKET constant_expression RIGHT_BRACKET
			case 117: return s(1); //init_declarator_list ::= single_declaration
			case 118: cast(n(1), VariableDeclaration).declarators.push(new Declarator(t(3).data, null, false)); return s(1); //init_declarator_list ::= init_declarator_list COMMA IDENTIFIER
			case 119: cast(n(1), VariableDeclaration).declarators.push(new ArrayDeclarator(t(3).data, cast n(5))); return s(1); //init_declarator_list ::= init_declarator_list COMMA IDENTIFIER LEFT_BRACKET constant_expression RIGHT_BRACKET
			case 120: cast(n(1), VariableDeclaration).declarators.push(new Declarator(t(3).data, cast n(5), false)); return s(1); //init_declarator_list ::= init_declarator_list COMMA IDENTIFIER EQUAL initializer
			case 121: return new VariableDeclaration(cast n(1), [new Declarator('', null, false)]); //single_declaration ::= fully_specified_type
			case 122: return new VariableDeclaration(cast n(1), [new Declarator(t(2).data, null, false)]); //single_declaration ::= fully_specified_type IDENTIFIER
			case 123: return new VariableDeclaration(cast n(1), [new ArrayDeclarator(t(2).data, cast n(4))]); //single_declaration ::= fully_specified_type IDENTIFIER LEFT_BRACKET constant_expression RIGHT_BRACKET
			case 124: return new VariableDeclaration(cast n(1), [new Declarator(t(2).data, cast n(4), false)]); //single_declaration ::= fully_specified_type IDENTIFIER EQUAL initializer
			case 125: return new VariableDeclaration(null, [new Declarator(t(2).data, null, true)]); //single_declaration ::= INVARIANT IDENTIFIER
			case 126: return s(1); //fully_specified_type ::= type_specifier
			case 127: cast(n(2), TypeSpecifier).qualifier = cast ev(1); //fully_specified_type ::= type_qualifier type_specifier
						return s(2);
			case 128: return TypeQualifier.CONST; //type_qualifier ::= CONST
			case 129: return TypeQualifier.ATTRIBUTE; //type_qualifier ::= ATTRIBUTE
			case 130: return TypeQualifier.VARYING; //type_qualifier ::= VARYING
			case 131: return TypeQualifier.INVARIANT_VARYING; //type_qualifier ::= INVARIANT VARYING
			case 132: return TypeQualifier.UNIFORM; //type_qualifier ::= UNIFORM
			case 133: return s(1); //type_specifier ::= type_specifier_no_prec
			case 134: cast(n(1), TypeSpecifier).precision = t(1).type; return s(1); //type_specifier ::= precision_qualifier type_specifier_no_prec
			case 135: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= VOID
			case 136: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= FLOAT
			case 137: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= INT
			case 138: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= BOOL
			case 139: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= VEC2
			case 140: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= VEC3
			case 141: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= VEC4
			case 142: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= BVEC2
			case 143: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= BVEC3
			case 144: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= BVEC4
			case 145: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= IVEC2
			case 146: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= IVEC3
			case 147: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= IVEC4
			case 148: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= MAT2
			case 149: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= MAT3
			case 150: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= MAT4
			case 151: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= SAMPLER2D
			case 152: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= SAMPLERCUBE
			case 153: return s(1); //type_specifier_no_prec ::= struct_specifier
			case 154: return new TypeSpecifier(t(1).type, t(1).data); //type_specifier_no_prec ::= TYPE_NAME
			case 155: return s(1); //precision_qualifier ::= HIGH_PRECISION
			case 156: return s(1); //precision_qualifier ::= MEDIUM_PRECISION
			case 157: return s(1); //precision_qualifier ::= LOW_PRECISION
			case 158: return new StructSpecifier(t(2).data, cast a(4)); //struct_specifier ::= STRUCT IDENTIFIER LEFT_BRACE struct_declaration_list RIGHT_BRACE
			case 159: return new StructSpecifier('', cast a(3)); //struct_specifier ::= STRUCT LEFT_BRACE struct_declaration_list RIGHT_BRACE
			case 160: return [n(1)]; //struct_declaration_list ::= struct_declaration
			case 161: a(1).push(n(2)); return s(1); //struct_declaration_list ::= struct_declaration_list struct_declaration
			case 162: return new StructDeclaration(cast n(1), cast a(2)); //struct_declaration ::= type_specifier struct_declarator_list SEMICOLON
			case 163: return [n(1)]; //struct_declarator_list ::= struct_declarator
			case 164: a(1).push(n(3)); return s(1); //struct_declarator_list ::= struct_declarator_list COMMA struct_declarator
			case 165: return new StructDeclarator(t(1).data); //struct_declarator ::= IDENTIFIER
			case 166: return new StructArrayDeclarator(t(1).data, cast n(3)); //struct_declarator ::= IDENTIFIER LEFT_BRACKET constant_expression RIGHT_BRACKET
			case 167: return s(1); //initializer ::= assignment_expression
			case 168: return s(1); //declaration_statement ::= declaration
			case 169: return new Statement(n(1), false); //statement_no_new_scope ::= compound_statement_with_scope
			case 170: return new Statement(n(1), false); //statement_no_new_scope ::= simple_statement
			case 171: return s(1); //simple_statement ::= declaration_statement
			case 172: return s(1); //simple_statement ::= expression_statement
			case 173: return s(1); //simple_statement ::= selection_statement
			case 174: return s(1); //simple_statement ::= iteration_statement
			case 175: return s(1); //simple_statement ::= jump_statement
			case 176: return new CompoundStatement([], true); //compound_statement_with_scope ::= LEFT_BRACE RIGHT_BRACE
			case 177: cast(n(2), CompoundStatement).newScope = true; return s(2); //compound_statement_with_scope ::= LEFT_BRACE statement_list RIGHT_BRACE
			case 178: return new Statement(n(1), true); //statement_with_scope ::= compound_statement_no_new_scope
			case 179: return new Statement(n(1), true); //statement_with_scope ::= simple_statement
			case 180: return new CompoundStatement([], false); //compound_statement_no_new_scope ::= LEFT_BRACE RIGHT_BRACE
			case 181: cast(n(2), CompoundStatement).newScope = false; return s(2); //compound_statement_no_new_scope ::= LEFT_BRACE statement_list RIGHT_BRACE
			case 182: return new CompoundStatement([cast n(1)]); //statement_list ::= statement_no_new_scope
			case 183: cast(n(1), CompoundStatement).statementList.push(cast n(2)); return s(1); //statement_list ::= statement_list statement_no_new_scope
			case 184: return new Statement(null, false); //expression_statement ::= SEMICOLON
			case 185: return new Statement(e(1), false); //expression_statement ::= expression SEMICOLON
			case 186: //selection_statement ::= IF LEFT_PAREN expression RIGHT_PAREN selection_rest_statement
			case 187: //selection_rest_statement ::= statement_with_scope ELSE statement_with_scope
			case 188: //selection_rest_statement ::= statement_with_scope
			case 189: return s(1); //condition ::= expression
			case 190: return new VariableDeclaration(cast n(1), [new Declarator(t(2).data, cast n(4), false)]); //condition ::= fully_specified_type IDENTIFIER EQUAL initializer
			case 191: return new WhileStatement(e(3), cast n(5)); //iteration_statement ::= WHILE LEFT_PAREN condition RIGHT_PAREN statement_no_new_scope
			case 192: return new DoWhileStatement(e(5), cast n(2)); //iteration_statement ::= DO statement_with_scope WHILE LEFT_PAREN expression RIGHT_PAREN SEMICOLON
			case 193: return new ForStatement(cast n(3), cast n(4), cast n(6)); //iteration_statement ::= FOR LEFT_PAREN for_init_statement for_rest_statement RIGHT_PAREN statement_no_new_scope
			case 194: return s(1); //for_init_statement ::= expression_statement
			case 195: return s(1); //for_init_statement ::= declaration_statement
			case 196: return s(1); //conditionopt ::= condition
			case 197: return null; //conditionopt ::=
			case 198: /* define ForRestStatement? */ //return s(1); //for_rest_statement ::= conditionopt SEMICOLON
			case 199: //for_rest_statement ::= conditionopt SEMICOLON expression
			case 200: return new JumpStatement(t(1).type); //jump_statement ::= CONTINUE SEMICOLON
			case 201: return new JumpStatement(t(1).type); //jump_statement ::= BREAK SEMICOLON
			case 202: return new JumpStatement(t(1).type); //jump_statement ::= RETURN SEMICOLON
			case 203: return new ReturnStatement(cast n(2)); //jump_statement ::= RETURN expression SEMICOLON
			case 204: return new JumpStatement(t(1).type); //jump_statement ::= DISCARD SEMICOLON
			case 205: return [n(1)]; //translation_unit ::= external_declaration
			case 206: a(1).push(cast n(2)); return s(1); //translation_unit ::= translation_unit external_declaration
			case 207: cast(n(1), Declaration).global = true; return s(1); //external_declaration ::= function_definition
			case 208: cast(n(1), Declaration).global = true; return s(1); //external_declaration ::= declaration
			case 209: return new FunctionDefinition(cast n(1), cast n(2)); //function_definition ::= function_prototype compound_statement_no_new_scope
		}

		var ruleNameReg = ~/^\w+/;
		ruleNameReg.match(ParserDebug.ruleString(ruleno));
		var ruleName = ruleNameReg.matched(0);
		Parser.warn('unhandled CreateNode rule, ($ruleno, $ruleName)');
		return null;
	}

	//#! list .data of symbols of current rule
	static function debug_allSymbols():String{
		var len = Parser.ruleInfo[ruleno].nrhs;
		var symbols = [for(n in 1...len+1) Std.string(s(n))];
		return [for(n in 1...len+1) Std.string( s(n) ) ].join(', ');
	}

	//Access rule symbols from left to right
	//s(1) gives the left most symbol
	static inline function s(n:Int){
		if(n <= 0) return null;
		//nrhs is the number of symbols in rule
		var j = Parser.ruleInfo[ruleno].nrhs - n;
		return stack[i - j].minor;
	}

	//Convenience functions for casting s(n).v
	static inline function n(m:Int):Node 
		return cast s(m).v;
	static inline function t(m:Int):Token
		return cast s(m).v;
	static inline function e(m:Int):Expression
		return cast(s(m).v, Expression);
	static inline function ev(m:Int):EnumValue
		return s(m) != null ? cast s(m).v : null;
	static inline function a(m):Array<Dynamic>
		return cast s(m).v;

	static inline function get_i() return Parser.i;
	static inline function get_stack() return Parser.stack;	
}