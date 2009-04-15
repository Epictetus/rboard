class Rank < ActiveRecord::Base
  has_many :users
    
  named_scope :custom, :conditions => { :custom => true }
  named_scope :for_user, lambda { |user| { :conditions => ["posts_required >= ?", user.posts.count] } } 
  
  validates_presence_of :name
  
  before_destroy :unassign_all_users

	def unassign_all_users
	  for user in User.find_all_by_rank_id(id)
	    user.update_attribute("rank_id", nil)
	  end
	end
end
