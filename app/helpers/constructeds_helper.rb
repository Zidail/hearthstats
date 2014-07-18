module ConstructedsHelper
  def klass_collection_for_select
    collection = [["- #{t('shared.matchlist.any_class')} -", '']]
    Klass.all.map { |k| collection << [k.name, k.id ]}
    
    collection
  end
  
  def items_per_page_for_select
    [10, 20, 50, 100].map { |i| ["#{i} #{t('.per_page')}", i] }
  end
  
  def days_options_for_select
    options = [["- #{t('.all_time')} -", 'all']]
    options << [t('.last_24_hours'), 1]
    [7, 30, 90].each { |num| options << [t('.last_days', num: num), num] }
    
    options
  end

  def cal_win_rate(wins, loss, draw)
    tot_games = wins + loss + draw
    return "N/A" if tot_games == 0 
    
    win_rate = wins.to_f / tot_games
    win_rate = (win_rate * 100).round(2)
    
    win_rate
  end

end
