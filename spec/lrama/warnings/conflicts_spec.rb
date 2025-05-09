# frozen_string_literal: true

RSpec.describe Lrama::Warnings::Conflicts do
  describe "#warn" do
    let(:y) do
      <<~STR
        %{
        // Prologue
        %}

        %union {
            int i;
            long l;
            char *str;
        }

        %token EOI 0 "EOI"
        %token <i> '\\'  "backslash"
        %token <i> '\13' "escaped vertical tab"
        %token <i> keyword_class
        %token <i> keyword_class2
        %token <l> tNUMBER
        %token <str> tSTRING
        %token <i> keyword_end "end"
        %token tPLUS  "+"
        %token tMINUS "-"
        %token tEQ    "="
        %token tEQEQ  "=="

        %type <i> class /* comment for class */
        %nterm <str> string /* comment for string */
        %type string_1 string_2 /* <tag> is omitted */

        %nonassoc tEQEQ
        %left  tPLUS tMINUS '>'
        %right tEQ

        %%

        program: class
              | '+' strings_1
              | '-' strings_2
              ;

        class : keyword_class tSTRING keyword_end %prec tPLUS
                  { code 1 }
              | keyword_class { code 2 } tSTRING '!' keyword_end { code 3 } %prec "="
              | keyword_class { code 4 } tSTRING '?' keyword_end { code 5 } %prec '>'
              ;

        strings_1: string_1
                ;

        strings_2: string_1
                | string_2
                ;

        string_1: string
                ;

        string_2: string '+'
                ;

        string: tSTRING
              ;

        %%
      STR
    end

    context "when warnings true" do
      it "has warns for s/r conflicts and r/r conflicts" do
        grammar = Lrama::Parser.new(y, "states/check_conflicts.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:warn)
        Lrama::Warnings.new(logger, true).warn(grammar, states)
        expect(logger).to have_received(:warn).with("shift/reduce conflicts: 2 found")
        expect(logger).to have_received(:warn).with("reduce/reduce conflicts: 1 found")
      end
    end

    context "when warnings false" do
      it "has not warns for s/r conflicts and r/r conflicts" do
        grammar = Lrama::Parser.new(y, "states/check_conflicts.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:warn)
        Lrama::Warnings.new(logger, false).warn(grammar, states)
        expect(logger).not_to have_received(:warn).with("shift/reduce conflicts: 2 found")
        expect(logger).not_to have_received(:warn).with("reduce/reduce conflicts: 1 found")
      end
    end
  end
end
