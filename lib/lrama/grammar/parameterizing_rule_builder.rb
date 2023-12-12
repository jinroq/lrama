module Lrama
  class Grammar
    class ParameterizingRuleBuilder
      attr_reader :name, :args, :rhs

      def initialize(name, args, rhs)
        @name = name
        @args = args
        @rhs = rhs
        @required_args_count = args.count
      end

      def build_rules(token, rule_counter, lhs_tag, line)
        validate_argument_number!(token)
        lhs = lhs_token(token)
        rules = []
        @rhs.each do |rhs|
          rules << Rule.new(id: rule_counter.increment, _lhs: lhs, _rhs: rhs_token(token, rhs), lhs_tag: lhs_tag, token_code: rhs.user_code, precedence_sym: rhs.precedence_sym, lineno: line)
        end
        ParameterizingRule.new(rules: rules, token: lhs)
      end

      private

      def validate_argument_number!(token)
        unless @required_args_count == token.args.count
          raise "Invalid number of arguments. expect: #{@required_args_count} actual: #{token.args.count}"
        end
      end

      def lhs_token(token)
        Lrama::Lexer::Token::Ident.new(s_value: "#{name}_#{token.args.map(&:s_value).join('_')}")
      end

      def rhs_token(token, rhs)
        rhs.symbols.map do |sym|
          idx = @args.index { |arg| arg.s_value == sym.s_value }
          if idx.nil?
            sym
          else
            token.args[idx]
          end
        end.compact
      end
    end
  end
end