# coding: utf-8

require "active_record"

class Tables < ActiveRecord::Migration
  class << self
    def users_create
      unless ActiveRecord::Base.connection.table_exists? :users
        create_table :users do |t|
          t.string :username, null: false
          t.string :password, null: false
          t.string :salt, null: false
          t.integer :role, default: 1
        end

        add_index :users, :username, unique: true
      end
    end

    def categories_create
      unless ActiveRecord::Base.connection.table_exists? :categories
        create_table :categories do |t|
          t.string :name, null: false
        end
      end
    end

    def register_files_create
      unless ActiveRecord::Base.connection.table_exists? :register_files
        create_table :register_files do |t|
          t.string :name, null: false
          t.string :ftype, null: false
          t.string :path, null: false
          t.integer :category_id, null: false
        end

        add_index :register_files, :path, unique: true
        add_index :register_files, :category_id
      end
    end

    def mail_templates_create
      unless ActiveRecord::Base.connection.table_exists? :mail_templates
        create_table :mail_templates do |t|
          t.string :to, null: false
          t.string :cc
          t.string :bcc
          t.string :from, null: false
          t.string :subject, null: false
          t.string :body, null: false
          t.integer :category_id, null: false 
        end
      end
    end

    def all_create
      users_create
      categories_create
      register_files_create
      mail_templates_create
    end
  end
end
