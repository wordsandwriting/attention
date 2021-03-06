class Friend
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  validates_presence_of :fbid, :account
  validates_uniqueness_of :fbid, :scope => :account

  field :fbid, :type => String
  field :name, :type => String
  field :username, :type => String
  field :email, :type => String
  field :following, :type => Boolean
  field :mutual_friends, :type => Integer

  def self.admin_fields
    {
      :fbid => :text,
      :name => :text,
      :username => :text,
      :email => :email,
      :following => :check_box,
      :mutual_friends => :number,
      :account_id => :lookup
    }
  end
  
  def get_info(account = self.account)
    account.login unless account.logged_in
    page = account.agent.get("https://m.facebook.com/#{fbid}")
    u = page.uri.path.split('/').last
    self.username = u unless u == 'profile.php'
    about = page.link_with(:text => /About/).try(:click)
    self.email = about.search("div[title='Email address'] td:last-child").try(:text)
    self.following = about.link_with(:text => 'Unfollow') ? true : false
    self.save
  end
  
  def follow(account = self.account)
    account.login unless account.logged_in
    page = account.agent.get("https://m.facebook.com/#{fbid}")
    page.link_with(:href => /subscribe\.php/).try(:click)
    page = account.agent.get("https://m.facebook.com/#{fbid}") # again
    if page.link_with(:href => /subscribe\.php/)
      raise "failed to follow #{name}"
    else
      update_attribute(:following, true) 
    end
  end  

  def unfollow(account = self.account)
    account.login unless account.logged_in
    page = account.agent.get("https://m.facebook.com/mbasic/more/?owner_id=#{fbid}&refid=17")
    page.link_with(:href => /subscriptions\/remove/).try(:click)
    update_attribute(:following, false)
  end

end
