module Rboard::UserExtension
  
  def self.included(klass)
    klass.class_eval do
      named_scope :recent, lambda { { :conditions => ["login_time > ?", 15.minutes.ago] } }

      validates_presence_of     :login, :email
      validates_presence_of     :password,                   :if => :password_required?
      validates_presence_of     :password_confirmation,      :if => :password_required?
      validates_length_of       :password, :within => 4..40, :if => :password_required?
      validates_confirmation_of :password,                   :if => :password_required?
      validates_length_of       :login,    :within => 3..40
      validates_length_of       :email,    :within => 3..100
      validates_uniqueness_of   :login, :email, :case_sensitive => false
      validates_uniqueness_of   :display_name, :allow_nil => true

      has_many :banned_ips, :foreign_key => "banned_by"
      has_many :edits
      has_many :inbox_messages, :class_name => "Message", :foreign_key => "to_id", :conditions => ["to_deleted = ?", false], :order => "id DESC"
      has_many :ip_users
      has_many :ips, :through => :ip_users, :order => "ips.updated_at DESC"
      has_many :outbox_messages, :class_name => "Message", :foreign_key => "from_id", :conditions => ["from_deleted = ?", false], :order => "id DESC"
      has_many :moderations
      has_many :posts
      has_many :reports
      has_many :sent_messages, :class_name => "Message", :foreign_key => "from_id"
      has_many :subscriptions
      has_many :subscribed_topics, :through => :subscriptions
      has_many :topics
      has_many :unread_messages, :class_name => "Message", :foreign_key => "to_id", :conditions => ["to_read = ? AND to_deleted = ?", false, false]

      has_attached_file :avatar, :styles => { :thumbnail => "100>" }

      belongs_to :banned_by, :class_name => "User", :foreign_key => "banned_by"
      belongs_to :style
      belongs_to :theme
      belongs_to :user_level

      before_create :encrypt_password
      before_create :set_theme
      before_create :set_user_level
      before_save :set_permalink
      
      attr_accessor :password
      
      def set_permalink
        self.permalink = to_s.parameterize
      end

      def set_theme
        self.theme = Theme.find(:first)
      end

      def to_s
        output = display_name unless display_name.blank?
        output ||= login
      end

      def to_param
        to_s.parameterize
      end

      #misc. user information
      def rank
        rank = Rank.find_by_id(rank_id)
    	  rank = Rank.find_by_custom(false, :conditions => ["posts_required <= ?", posts.size], :order => "posts_required DESC") if rank.nil?
    	  rank.nil? ? user_level.name : rank.name
      end

      #permission checking 
      def set_user_level
        self.user_level = if User.count == 0
          UserLevel.find_by_name("Administrator")
        else
          UserLevel.find_by_name("User")
        end
      end

      def admin?
        user_level.to_s == "Administrator"
      end

      def moderator?
        user_level.to_s == "Moderator"
      end

      def user?
        user_level.to_s == "User"
      end

      def banned?
        ban_time.nil? ? false : ban_time > Time.now
      end

      def has_avatar?
        !avatar_file_name.blank?
      end
      
      def online?
        !!(login_time && login_time > Time.now - 15.minutes)
      end
    end
  end
  
end