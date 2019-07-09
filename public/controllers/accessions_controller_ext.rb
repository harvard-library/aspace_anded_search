::AccessionsController
class AccessionsController
  def index
    if !params.fetch(:q, nil)
      DEFAULT_AC_SEARCH_PARAMS.each do |k, v|
        params[k] = v
      end
    end
    @repo_id = params.fetch(:rid, nil)
    if @repo_id
      @base_search =  "/repositories/#{@repo_id}/accessions?"
      repo = archivesspace.get_record("/repositories/#{@repo_id}")
      @repo_name = repo.display_string
    else
      @base_search = '/accessions?'
    end
    page = Integer(params.fetch(:page, "1"))
    search_opts = default_search_opts( DEFAULT_AC_SEARCH_OPTS)
    search_opts['fq'] = AdvancedQueryBuilder.new.and('repository', "/repositories/#{@repo_id}") if @repo_id
    begin
      set_up_and_run_search( DEFAULT_AC_TYPES, DEFAULT_AC_FACET_TYPES,  search_opts, params)
    rescue NoResultsError
      flash[:error] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: '/') and return
    rescue Exception => error
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: '/') and return
    end

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

    @page_title = I18n.t('accession._plural')
    @results_type = @page_title
    @no_statement = true
    render 'search/search_results'

  end
end
