class Api::V3::MatchesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_req, except: [:query]

  respond_to :json

  def query
    # Check Params
    params[:mode].nil?

    if params[:deck_id].present?
      result = Match.joins(:deck).where('decks.id' => params[:deck_id], user_id: current_user.id)
    else
      result = Match.where(user_id: current_user.id)
    end
    if params[:mode].present?
      result = result.where(mode_id: params[:mode])
    end
    if params[:result].present?
      result = result.where(result_id: params[:result])
    end
    if params[:klass].present?
      result = result.where(klass_id: params[:klass])
    end
    if params[:oppclass].present?
      result = result.where(oppclass_id: params[:oppclass])
    end
    if params[:coin].present?
      if params[:coin] == 'true'
        coin = true
      else
        coin = false
      end
      result = result.where(coin: coin)
    end
    if params[:season].present?
      if params[:season] == "0"
        result = result.where(season_id: current_season)
      else
        result = result.where(season_id: params[:season])
      end
    end
    if params[:last_id]
      result = result.where('id > ?', params[:last_id].to_i)
    end

    merged_result = result.map { |r| r.attributes.merge(deck_id: r.deck.id)}
    render json: { status: "success", data: merged_result }
  end

  def create
    _req = @req

    if _req[:mode] == "Arena"
      begin
        arena_run = ArenaRun.find(_req[:arena_run_id])
      rescue ActiveRecord::RecordNotFound => e
        render json: {status: 400, message: e.message} and return
      end
      deck = arena_run.deck
      if deck.nil?
        klass_id = Klass::LIST.invert[_req[:class]]
      else
        klass_id = deck.klass_id
      end
      match = parse_match(_req, klass_id)
      if match.save
        submit_arena_match(current_user, match, klass_id)
        render json: {status: 200, data: match}
      else
        render json: {status: 400, message: match.errors.full_messages}
      end
    else
      begin
        deck = Deck.find(_req[:deck_id])
        klass_id = deck.klass_id
      rescue ActiveRecord::RecordNotFound => e
        render json: {status: 400, message: e.message} and return
      end
      match = parse_match(_req, klass_id)
      if match.save
        MatchRank.create(match_id: match.id, rank_id: _req[:ranklvl].to_i)
        MatchDeck.create(match_id: match.id,
                         deck_id: deck.id,
                         deck_version_id: _req[:deck_version_id].to_i
                        )
        render json: {status: 200, data: match}
      else
        render json: {status: 400, message: match.errors.full_messages}
      end
    end
  end

  def multi_create
    begin
      deck = Deck.find(@req[:deck_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: {status: 400, message: e.message} and return
    end
    # Match.delay(:queue => 'multicreate_queue').mass_import_new_matches(@req[:matches].map(&:symbolize_keys), deck.id, deck.klass_id, current_user.id)
    response = Match.mass_import_new_matches(@req[:matches].map(&:symbolize_keys), deck.id, deck.klass_id, current_user.id)
    render json: {status: 200, data: response}
  end

  def after_date
    req = @req
    api_response = []
    matches = Match.where{(user_id == my{current_user.id}) & (created_at >= DateTime.strptime(req[:date], '%s'))}
    matches.joins(:match_deck).each do |match|
      api_response << { :deck_id => match.match_deck.deck_id,
                        :deck_version_id => match.match_deck.deck_version_id,
                        :match => match,
                        :ranklvl => match.rank.try(:id)
      }
    end

    render json: { status: 200, data: api_response}
  end

  def multi_destroy
    unless match_belongs_to_user?(current_user, @req[:match_id])
      response = {status: 400, message: "At least one or more of the matches do not belong to the user"}
    else
      Match.find(@req[:match_id]).map(&:destroy)
      response = {status: 200}
    end
    render json: response
  end

  def delete
    unless match_belongs_to_user?(current_user, @req[:match_id])
      response = {status: 400, message: "At least one or more of the matches do not belong to the user"}
    else
      Match.find(@req[:match_id]).map(&:destroy)
      response = {status: 200}
    end
    render json: response
  end

  def destroy
    match = Match.find(params[:id])
    if match.user_id != current_user.id
      render json: {status: 401} and return
    end
    if match.destroy
      response = {status: 200}
    else
      response = {status: 400}
    end
    render json: response
  end

  def move
    unless match_belongs_to_user?(current_user, @req[:match_id])
      response = {status: 400, message: "At least one or more of the matches do not belong to the user"}
    else
      match_decks = Match.find(@req[:match_id]).map(&:match_deck)
      match_decks.map { |match_deck| match_deck.update_attribute(:deck_id, @req[:deck_id].to_i)}
      response = {status: 200}
    end
    render json: response
  end

  private

  def match_belongs_to_user?(user, match_ids)
    user_match_ids = user.matches.pluck(:id)


    array_subset?(match_ids, user_match_ids)
  end

  def array_subset?(child, parent)
    parent.length - (parent - child).length == child.length
  end

  def create_new_deck(user, slot, klass)
    new_deck = Deck.new
    new_deck.user_id = user.id
    new_deck.active = true
    new_deck.slot = slot
    new_deck.klass = klass
    new_deck.name = "Unnamed #{klass.name}"
    if new_deck.save
      return new_deck
    else
      return nil
    end
  end

  def submit_arena_match(user, match, userclass)
    # associate the match with an arena run
    arena_run = ArenaRun.where(user_id: user.id, complete: false).last
    if arena_run.nil? || arena_run.klass_id != userclass
      if arena_run.nil?
        message = "New #{Klass::LIST[userclass]} arena run created"
      end
      arena_run = ArenaRun.new(user_id: user.id, klass_id: userclass)
      arena_run.save
      if arena_run.klass_id != userclass
        message = "Existing #{arena_run.klass.name} arena run did not match submitted #{Klass::LIST[userclass]} match. New #{Klass::LIST[userclass]} arena run created."
      end
    end
    # check for completed arena run
    if arena_run.num_losses >= 3 || arena_run.num_wins >= 12
      arena_run.update_attribute(:complete, true)
      message = "Existing #{Klass::LIST[userclass]} run already had #{arena_run.num_losses >= 3 ? "3 losses" : "12 wins"}. New #{match.klass.name} run created."
      arena_run = ArenaRun.new(user_id: user.id, klass_id: match.klass.id)
      arena_run.save
    end
    MatchRun.new(match_id: match.id, arena_run_id: arena_run.id).save!
  end


  def parse_match_sql(_params, klass_id)
    _params = _params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    # Parse params to get variables
    mode     = Mode::LIST.invert[_params[:mode]] || 'NULL'
    oppclass = Klass::LIST.invert[_params[:oppclass]] || 'NULL'
    result   = Match::RESULTS_LIST.invert[_params[:result]] || 'NULL'
    coin     = _params[:coin] == "true"
    match_str = "(#{current_user.id},#{mode},#{klass_id},#{result},#{coin},#{oppclass},'#{_params[:oppname] || 'NULL'}',#{_params[:numturns] || 'NULL'},#{_params[:duration] || 'NULL'},'#{_params[:notes] || 'NULL'}',true,'#{Time.now.to_s(:db)}','#{Time.now.to_s(:db)}')"

    match_str
  end
  def parse_match(_params, klass_id)
    _params = _params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    # Parse params to get variables
    mode     = Mode::LIST.invert[_params[:mode]]
    oppclass = Klass::LIST.invert[_params[:oppclass]]
    result   = Match::RESULTS_LIST.invert[_params[:result]]
    coin     = _params[:coin] == "true"

    # Create new match
    match             = Match.new
    match.user_id     = current_user.id
    match.mode_id     = mode
    match.klass_id    = klass_id
    match.result_id   = result
    match.coin        = coin
    match.oppclass_id = oppclass
    match.oppname     = _params[:oppname]
    match.numturns    = _params[:numturns]
    match.duration    = _params[:duration]
    match.notes       = _params[:notes]
    match.appsubmit   = true
    if _params[:created_at]
      match.created_at  = _params[:created_at].to_time
    end

    match
  end
end
