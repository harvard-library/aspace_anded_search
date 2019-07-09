::SubjectsController
class SubjectsController
  def index
    repo_id = params.fetch(:rid, nil)
    if !params.fetch(:q, nil)
      DEFAULT_SUBJ_SEARCH_PARAMS.each do |k, v|
        params[k] = v unless params.fetch(k,nil)
      end
    end
    search_opts = default_search_opts(DEFAULT_SUBJ_SEARCH_OPTS)
    search_opts['fq'] = AdvancedQueryBuilder.new.and('used_within_published_repository', "/repositories/#{repo_id}") if repo_id
    @base_search  =  repo_id ? "/repositories/#{repo_id}/subjects?" : '/subjects?'
    default_facets = repo_id ? [] : ['used_within_published_repository']
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search(['subject'], default_facets, search_opts, params)
    rescue NoResultsError
      flash[:error] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: '/') and return
    rescue Exception => error
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: '/subjects' ) and return
    end

    @context = repo_context(repo_id, 'subject')
    if @results['total_hits'] > 1
      @search[:dates_within] = false
      @search[:text_within] = true
    end

    @page_title = I18n.t('subject._plural')
    @results_type = @page_title
    all_sorts = Search.get_sort_opts
    @sort_opts = []
    %w(title_sort_asc title_sort_desc).each do |type|
      @sort_opts.push(all_sorts[type])
    end

    if params[:q].size > 1 || params[:q][0] != '*'
      @sort_opts.unshift(all_sorts['relevance'])
    end
    @no_statement = true
    render 'search/search_results'
  end

  def fetch_subject_results(title, uri, params)
    @results = []
    qry = "subjects:\"#{title}\" AND types:pui"
    @base_search = "#{uri}?"
    search_opts =  default_search_opts(DEFAULT_SUBJ_SEARCH_OPTS)
    search_opts['fq'] = AdvancedQueryBuilder.new.and('subjects', title).and('types', 'pui')
    set_up_search(DEFAULT_SUBJ_TYPES, DEFAULT_SUBJ_FACET_TYPES, search_opts, params, qry)
   # we do this to compensate for the way @base_search gets munged in the setup
    @base_search= @base_search.sub("q=#{qry}", '')
    page = Integer(params.fetch(:page, "1"))
    @results =  archivesspace.search(@query,page, @criteria)
    if @results['total_hits'] > 0
      process_search_results(@base_search)
    else
      @results = []
    end
    @results
  end

end
