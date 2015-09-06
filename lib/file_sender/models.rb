# coding: utf-8

module PureSender
  ActiveRecord::Base.establish_connection(Application.database[Application.environment.to_s])

  class User < ActiveRecord::Base
    include Passwd::ActiveRecord
    define_column id: :username, salt: :salt, password: :password

    validates :username, presence: true, uniqueness: true

    def root?
      self.role == 0
    end
  end

  class Category < ActiveRecord::Base
    validates :name, presence: true, uniqueness: true
    has_many :register_files, dependent: :destroy
    has_one :mail_template
  end

  class RegisterFile < ActiveRecord::Base
    #validates :name, presence: true, uniqueness: true
    validates :name, presence: true
    validates :path, presence: true, uniqueness: true
    validates :category_id, presence: true
    belongs_to :category
  end

  class MailTemplate < ActiveRecord::Base
    validates :to, presence: true
    #validates :cc
    #validates :bcc
    validates :from, presence: true
    validates :subject, presence: true
    validates :body, presence: true
    validates :category_id, presence: true
    belongs_to :category
  end
end
