# frozen_string_literal: true

module Gloss
  class Scope < Hash
    def [](k)
      fetch(k) { raise "Undefined expression for current scope: #{k}" }
    end
  end
end
