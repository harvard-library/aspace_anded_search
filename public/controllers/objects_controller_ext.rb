::ObjectsController
class ObjectsController

  def index
    repo_id = params.fetch(:rid, nil)
     if !params.fetch(:q,nil)
      params[:q] = ['*']
      params[:limit] = 'digital_object,archival_object' unless params.fetch(:limit,nil)
      params[:op] = ['OR']
    end
    page = Integer(params.fetch(:page, "1"))
    search_opts = default_search_opts(DEFAULT_OBJ_SEARCH_OPTS)
    search_opts['fq'] = AdvancedQueryBuilder.new.and('repository', "/repositories/#{repo_id}") if repo_id
    @base_search = repo_id ? "/repositories/#{repo_id}/objects?" : '/objects?'

    begin
      set_up_and_run_search( params[:limit].split(","), DEFAULT_OBJ_FACET_TYPES, search_opts, params)
    rescue NoResultsError
      flash[:error] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: '/') and return
    rescue Exception => error
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: '/objects' ) and return
    end

    @context = repo_context(repo_id, 'record')
    if @results['total_hits'] > 1
      @search[:dates_within] = true if params.fetch(:filter_from_year,'').blank? && params.fetch(:filter_to_year,'').blank?
      @search[:text_within] = true
    end
    @sort_opts = []
    all_sorts = Search.get_sort_opts
    all_sorts.delete('relevance') unless params[:q].size > 1 || params[:q] != '*'
    all_sorts.keys.each do |type|
       @sort_opts.push(all_sorts[type])
    end

    @page_title = I18n.t('record._plural')
    @results_type = @page_title
    @no_statement = true
    render 'search/search_results'
  end
end
