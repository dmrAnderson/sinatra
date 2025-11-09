# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:mobility_string_translations) do
      primary_key :id
      String :locale, null: false
      String :key, null: false
      String :value
      Integer :translatable_id, null: false
      String :translatable_type, null: false
      DateTime :created_at
      DateTime :updated_at
      index [:translatable_id, :translatable_type, :key], name: "index_mobility_string_translations_on_translatable_attribute"
      index [:translatable_id, :translatable_type, :locale, :key], unique: true, name: "index_mobility_string_translations_on_keys"
      index [:translatable_type, :key, :value, :locale], name: "index_mobility_string_translations_on_query_keys"
    end

    create_table(:mobility_text_translations) do
      primary_key :id
      String :locale, null: false
      String :key, null: false
      Text :value
      Integer :translatable_id, null: false
      String :translatable_type, null: false
      DateTime :created_at
      DateTime :updated_at
      index [:translatable_id, :translatable_type, :key], name: "index_mobility_text_translations_on_translatable_attribute"
      index [:translatable_id, :translatable_type, :locale, :key], unique: true, name: "index_mobility_text_translations_on_keys"
    end
  end
end

