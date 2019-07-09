::ResourcesController
class ResourcesController
  # present a list of resources.  If no repository named, just get all of them.
  def index
    @repo_id = params.fetch(:rid, nil)
    if @repo_id
      @base_search = "/repositories/#{@repo_id}/resources?"
      repo = archivesspace.get_record("/repositories/#{@repo_id}")
      @repo_name = repo.display_string
    else
      @base_search = "/repositories/resources?"
    end
    search_opts = default_search_opts( DEFAULT_RES_INDEX_OPTS)
    search_opts['fq'] = AdvancedQueryBuilder.new.and('repository', "/repositories/#{@repo_id}") if @repo_id

    DEFAULT_RES_SEARCH_PARAMS.each do |k,v|
      params[k] = v unless params.fetch(k, nil)
    end
    page = Integer(params.fetch(:page, "1"))
    facet_types = DEFAULT_RES_FACET_TYPES.dup
    facet_types.unshift('repository') if !@repo_id
    begin
      set_up_and_run_search(['resource'], facet_types, search_opts, params)
    rescue NoResultsError
      flash[:error] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: '/') and return
    rescue Exception => error
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: '/' ) and return
    end

    @context = repo_context(@repo_id, 'resource')
     if @results['total_hits'] > 1
        @search[:dates_within] = true if params.fetch(:filter_from_year,'').blank? && params.fetch(:filter_to_year,'').blank?
        @search[:text_within] = true
      end
    @page_title = I18n.t('resource._plural')
    @results_type = @page_title
    @sort_opts = []
    all_sorts = Search.get_sort_opts
    all_sorts.delete('relevance') unless params[:q].size > 1 || params[:q] != '*'
    all_sorts.keys.each do |type|
       @sort_opts.push(all_sorts[type])
    end

    if params[:q].size > 1 || params[:q][0] != '*'
      @sort_opts.unshift(all_sorts['relevance'])
    end
    @result_props = {
      :no_res => true
    }
    @no_statement = true
#    if @results['results'].length == 1
#      @result =  @results['results'][0]
#      render 'resources/show'
#    else
      render 'search/search_results'
#    end
  end

  def search
    repo_id = params.require(:repo_id)
    res_id = "/repositories/#{repo_id}/resources/#{params.require(:id)}"
    search_opts = DEFAULT_RES_SEARCH_OPTS
    search_opts['fq'] = ["resource:\"#{res_id}\""]
    search_opts['fq'] = AdvancedQueryBuilder.new.and('resource', res_id)
    params[:res_id] = res_id
#    q = params.fetch(:q,'')
    unless params.fetch(:q,nil)
      params[:q] = ['*']
    end
    @base_search = "#{res_id}/search?"
    begin
      set_up_advanced_search(DEFAULT_RES_TYPES, DEFAULT_RES_FACET_TYPES, search_opts, params)
    rescue Exception => error
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: res_id ) and return
    end

    page = Integer(params.fetch(:page, "1"))
    @results = archivesspace.advanced_search('/search',page, @criteria)
    if @results['total_hits'].blank? ||  @results['total_hits'] == 0
      flash[:notice] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: @base_search)
    else
      process_search_results(@base_search)
      title = ''
      title =  strip_mixed_content(@results['results'][0]['_resolved_resource']['json']['title']) if @results['results'][0] &&  @results['results'][0].dig('_resolved_resource', 'json')

      @context = []
      @context.push({:uri => "/repositories/#{repo_id}",
                      :crumb => get_pretty_facet_value('repository', "/repositories/#{repo_id}")})
      unless title.blank?
        @context.push({:uri => "#{res_id}", :crumb => title})
      end
      if @results['total_hits'] > 1
        @search[:dates_within] = true if params.fetch(:filter_from_year,'').blank? && params.fetch(:filter_to_year,'').blank?
        @search[:text_within] = true
      end
      @page_title = I18n.t('actions.search_in', :type => (title.blank? ? I18n.t('resource._singular') : "\"#{title}\""))
      @sort_opts = []
      all_sorts = Search.get_sort_opts
      all_sorts.delete('relevance') unless params[:q].size > 1 || params[:q] != '*'
      all_sorts.keys.each do |type|
        @sort_opts.push(all_sorts[type])
      end
      @no_statement = true
# Pry::ColorPrinter.pp @results['results'][0]['_resolved_resource']['json']
      render 'search/search_results'
    end
  end

  def fetch_containers(resource_uri, page_uri, params)
    qry = "collection_uri_u_sstr:\"#{resource_uri}\" AND (#{CONTAINER_QUERY})"
    @base_search = "#{page_uri}?"
    search_opts =  default_search_opts({
      'sort' => 'typeahead_sort_key_u_sort asc',
      'facet.mincount' => 1
    })
    search_opts['fq'] = AdvancedQueryBuilder.new.and('collection_uri_u_sstr', resource_uri).and('types', 'pui').and('types', 'pui_container')

    set_up_search(['pui_container'], ['type_enum_s', 'published_series_title_u_sstr'], search_opts, params, qry)
    @base_search= @base_search.sub("q=#{qry}", '')
    page = Integer(params.fetch(:page, "1"))

    @results = archivesspace.search(@query, page, @criteria)

    if @results['total_hits'] > 0
      process_search_results(@base_search)
    else
      @results = []
    end
  end

end
