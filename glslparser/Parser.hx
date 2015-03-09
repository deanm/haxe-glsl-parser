/*
	LALR parser based on lemon parser generator
	http://www.hwaci.com/sw/lemon/

	#Notes
	- minor is our node object! (not a Token) (it's not used in the parsing itself, it's just parsed around and stored in the stack)
*/

package glslparser;

import glslparser.Tokenizer.Token;
import glslparser.Tokenizer.TokenType;

class Parser{
	//state machine variables
	static var i:Int; //stack index
	static var stack:Stack;
	static var errorCount:Int;

	static public function parseTokens(tokens:Array<Token>){
		//init
		i = 0;
		errorCount = 0;
		stack = [{
			stateno: 0,
			major: 0,
			minor: null
		}];

		var lastToken = null;
		for(t in tokens){
			if(ignoredTokens.indexOf(t.type) != -1) continue;
			parseStep(tokenIdMap.get(t.type), t);
			lastToken = t;
		}

		//eof step
		parseStep(0, lastToken);//using the lastToken for the EOF step allows better error reporting if it fails
		return {};
	}

	//for each token, major = tokenId
	static function parseStep(major:Int, minor:MinorType){
		var act:Int, 
			atEOF:Bool = (major == 0),
			errorHit:Bool = false;

		do{
			act = findShiftAction(major);
			if(act < nStates){
				assert( !atEOF );
				shift(act, major, minor); //push a leaf/token to the stack
				errorCount--;
				major = illegalSymbolNumber;
			}else if(act < nStates + nRules){
				reduce(act - nStates);
			}else{
				//syntax error
				assert( act == errorAction );
				if(errorsSymbol){
					//#! error recovery code if the error symbol in the grammar is supported
				}else{
					if(errorCount <= 0){
						syntaxError(major, minor);
					}

					errorCount = 3;
					if( atEOF ){
						parseFailed(minor);
					}
					major = illegalSymbolNumber;
				}
			}
		}while( major != illegalSymbolNumber && i >= 0);

		return;
	}

	static function popStack(){
		if(i < 0) return 0;
		var major = stack.pop().major;
		i--;
		return major;
	}

	//Find the appropriate action for a parser given the terminal
	//look-ahead token iLookAhead.
	static function findShiftAction(iLookAhead:Int){
		var stateno = stack[i].stateno;
		var j:Int = shiftOffset[stateno];

		if(stateno > shiftCount || j == shiftUseDefault){
			return defaultAction[stateno];
		}

		assert(iLookAhead != illegalSymbolNumber);

		j += iLookAhead;

		if(j < 0 || j >= actionCount || lookahead[j] != iLookAhead){
			return defaultAction[stateno];
		}

		return action[j];
	}

	//Find the appropriate action for a parser given the non-terminal
	//look-ahead token iLookAhead.
	static function findReduceAction(stateno:Int, iLookAhead:Int){
		var j:Int;

		if(errorsSymbol){
			if(stateno > reduceCount) return defaultAction[stateno];
		}else{
			assert( stateno <= reduceCount);
		}

		j = reduceOffset[stateno];

		assert( j != reduceUseDefault );
		assert( iLookAhead != illegalSymbolNumber );
		j += iLookAhead;

		if(errorsSymbol){
			if( j < 0 || j >= actionCount || lookahead[j] != iLookAhead ){
				return defaultAction[stateno];
			}
		}else{
			assert( j >= 0 && j < actionCount );
			assert( lookahead[j] == iLookAhead );
		}

		return action[j];
	}

	static function shift(newState:Int, major:Int, minor:MinorType){
		i++;
		stack[i] = {
			stateno: newState,
			major: major,
			minor: minor
		};
	}

	static function reduce(ruleno:Int){
		var goto:Int;               //next state
		var act:Int;                //next action
		var size:Int;               //amount to pop the stack

		//new node generated after reducing with this rule
		var newNode = ParserAST.createNode(ruleno); //trigger custom reduce behavior

		trace('Reduce ($ruleno) [$newNode] '+ParserDebug.ruleString(ruleno));

		goto = ruleInfo[ruleno].lhs;
		size = ruleInfo[ruleno].nrhs;
		i -= size;

		act = findReduceAction(stack[i].stateno, goto);

		if(act < nStates){
			shift(act, goto, newNode); //push a node (the result of a rule) to the stack
		}else{
			assert( act == nStates + nRules + 1);
			accept();
		}
	}

	static function accept() while(i >= 0) popStack();

	static function syntaxError(major:Int, minor:MinorType){
		warn('syntax error, $minor');
	}//#! needs improving

	static function parseFailed(minor:MinorType){
		warn('parse failed, $minor');
	}

	//Utils
	static function assert(cond:Bool, ?pos:haxe.PosInfos)
		if(!cond) warn('assert failed in ${pos.className}::${pos.methodName} line ${pos.lineNumber}');

	//Error Reporting
	static function warn(msg){
		trace('Parser Warning: $msg');
	}

	static function error(msg){
		throw 'Parser Error: $msg';
	}

	//Language Data & Parser Settings
	static inline var errorsSymbol:Bool       = ParserData.errorsSymbol;
	//consts
	static inline var illegalSymbolNumber:Int = ParserData.illegalSymbolNumber;

	static inline var nStates                 = ParserData.nStates;
	static inline var nRules                  = ParserData.nRules;
	static inline var noAction                = nStates + nRules + 2;
	static inline var acceptAction            = nStates + nRules + 1;
	static inline var errorAction             = nStates + nRules;

	//tables
	static var actionCount                    = ParserData.actionCount;
	static var action:Array<Int>              = ParserData.action;
	static var lookahead:Array<Int>           = ParserData.lookahead;

	static inline var shiftUseDefault         = ParserData.shiftUseDefault;
	static inline var shiftCount              = ParserData.shiftCount;
	static inline var shiftOffsetMin          = ParserData.shiftOffsetMin;
	static inline var shiftOffsetMax          = ParserData.shiftOffsetMax;
	static var shiftOffset:Array<Int>         = ParserData.shiftOffset;

	static inline var reduceUseDefault        = ParserData.reduceUseDefault;
	static inline var reduceCount             = ParserData.reduceCount;
	static inline var reduceMin               = ParserData.reduceMin;
	static inline var reduceMax               = ParserData.reduceMax;
	static var reduceOffset:Array<Int>        = ParserData.reduceOffset;

	static var defaultAction:Array<Int>       = ParserData.defaultAction;

	//rule info table
	static var ruleInfo:Array<RuleInfoEntry>  = ParserData.ruleInfo;

	//tokenId
	static var tokenIdMap:Map<TokenType, Int> = ParserData.tokenIdMap;

	//skip-over tokens
	static var ignoredTokens:Array<TokenType> = ParserData.ignoredTokens;
}

typedef NodeType = glslparser.ParserAST.Node;

//a minor may be a token or a node
enum EMinorType{
	Token(t:Token);
	Node(n:NodeType);
}

abstract MinorType(EMinorType){
	public inline function new(e:EMinorType) this = e;

	public var v(get, never):Dynamic;
	public var type(get, never):EMinorType;

	inline function get_v() return this.getParameters()[0];

	@:to inline function get_type():EMinorType return this;

	@:from static inline function fromToken(t:Token) return new MinorType(Token(t));
	@:from static inline function fromNode(n:NodeType) return new MinorType(Node(n));
}

abstract RuleInfoEntry(Array<Int>) from Array<Int> {
	public var lhs(get, set):Int;
	public var nrhs(get, set):Int;
	
	function get_lhs()return this[0];
	function set_lhs(v:Int)return this[0] = v;
	function get_nrhs()return this[1];
	function set_nrhs(v:Int)return this[1] = v;
}

typedef StackEntry = {
	var stateno:Int;
	var major:Int;
	var minor:MinorType;
}

typedef Stack = Array<StackEntry>;