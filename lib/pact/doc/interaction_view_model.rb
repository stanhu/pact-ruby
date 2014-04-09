require 'pact/consumer_contract/active_support_support'

module Pact
  module Doc
    class InteractionViewModel

      include Pact::ActiveSupportSupport

      def initialize interaction, consumer_contract
        @interaction = interaction
        @consumer_contract = consumer_contract
      end

      def id
        @id ||= begin
          if has_provider_state?
            "#{description} given #{interaction.provider_state}"
          else
            interaction.description
          end.gsub(/\s+/,'_')
        end
      end

      def request_method
        interaction.request.method.upcase
      end

      def request_path
        interaction.request.path
      end

      def response_status
        interaction.response['status']
      end

      def consumer_name
        @consumer_contract.consumer.name
      end

      def provider_name
        @consumer_contract.provider.name
      end

      def has_provider_state?
        @interaction.provider_state && !@interaction.provider_state.empty?
      end

      def provider_state start_of_sentence = false
        apply_capitals(@interaction.provider_state.strip, start_of_sentence)
      end

      def description start_of_sentence = false
        apply_capitals(@interaction.description.strip, start_of_sentence)
      end

      def request
        fix_json_formatting JSON.pretty_generate(clean_request)
      end

      def response
        fix_json_formatting JSON.pretty_generate(clean_response)
      end

      def sortable_id
        @sortable_id ||= "#{interaction.description.downcase} #{interaction.response['status']} #{(interaction.provider_state || '').downcase}"
      end

      private

      def clean_request
        ordered_clean_hash Reification.from_term(interaction.request).to_hash
      end

      def clean_response
        ordered_clean_hash Reification.from_term(interaction.response)
      end

      def ordered_clean_hash source
        ordered_keys.each_with_object({}) do |key, target|
          if source.key? key
            target[key] = source[key] unless value_is_an_empty_hash_that_is_not_request_body(source[key], key)
          end
        end
      end

      def value_is_an_empty_hash_that_is_not_request_body value, key
        value.is_a?(Hash) && value.empty? && key != :body
      end

      def ordered_keys
        [:method, :path, :query, :headers, :body, "status", "headers","body"]
      end

      def remove_key_if_empty key, hash
        hash.delete(key) if hash[key].is_a?(Hash) && hash[key].empty?
      end

      def apply_capitals string, start_of_sentence = false
        start_of_sentence ? capitalize_first_letter(string) : lowercase_first_letter(string)
      end

      def capitalize_first_letter string
        string[0].upcase + string[1..-1]
      end

      def lowercase_first_letter string
        string[0].downcase + string[1..-1]
      end

      attr_reader :interaction, :consumer_contract

    end
  end
end