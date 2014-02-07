class ArenaRun < ActiveRecord::Base
  attr_accessible :class, :gold, :dust, :completed, :user_id, :userclass, :notes, :complete
  
  has_many :arenas
  has_many :match_run
  has_many :matches, :through => :match_run, :dependent => :destroy

  after_destroy :delete_all_arena

  def delete_all_arena
  	Arena.destroy_all(:arena_run_id => self.id)
  end

  def self.averageWins(race, userid)
  	arena_games = ArenaRun.where(user_id: userid, :userclass => race)
  	wins = arena_games.map { |e| e.arenas.where(win:true).count }
  	average_win = wins.compact.inject{ |sum, el| sum + el }.to_f / wins.size
  	average_win = -1 if average_win.nan?

  	average_win
  end

  def self.totalGold(userid)
  	arena_games = ArenaRun.where(user_id: userid)
  	goldamount = arena_games.map { |e| e.gold }
  	total_gold = 0
  	goldamount.each do |g|
  		total_gold += g unless g.nil?
  	end
  	if total_gold.nil?
  		total_gold = 0
  	end

  	total_gold
  end

  def self.totalDust(userid)
  	arena_games = ArenaRun.where(user_id: userid)
  	dustamount = arena_games.map { |e| e.dust }
  	total_dust = 0
  	dustamount.each do |g|
  		total_dust += g unless g.nil?
  	end
  	if total_dust.nil?
  		total_dust = 0
  	end

  	total_dust
  end

  def self.classArray(userid)
    classes = ['Druid' ,'Hunter', 'Mage', 'Paladin', 'Priest', 'Rogue', 'Shaman', 'Warlock', 'Warrior']
    class_array = Hash.new
  	classes.each do |c|
  		class_avgwins = ArenaRun.averageWins(c, userid)
  		class_runs = ArenaRun.where( userclass: c, user_id: userid ).count
  		class_winrate = Arena.where( userclass: c, user_id: userid, win: true ).count.to_f / Arena.where( userclass: c, user_id: userid ).count
  		class_coinrate = Arena.where( userclass: c, user_id: userid, win: true, gofirst: false ).count.to_f / Arena.where( userclass: c, user_id: userid, gofirst: false).count
  		class_nocoinrate = Arena.where( userclass: c, user_id: userid, win: true, gofirst: true ).count.to_f / Arena.where( userclass: c, user_id: userid, gofirst: true).count

  		class_array[c] = [["Average wins", class_avgwins],
  											["Total runs with class", class_runs],
  											["Class winrate", class_winrate],
  											["Win rate with coin", class_coinrate],
  											["Win rate without coin", class_nocoinrate]]
  	end

  	class_array
  end
end
