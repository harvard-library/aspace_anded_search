::ContainersController
class ContainersController
  def show
    uri = "/repositories/#{params[:rid]}/top_containers/#{params[:id]}"
    begin
      @criteria = {}
      @result =  archivesspace.get_record(uri, @criteria)
      @repo_info = @result.repository_information
      @page_title = "#{I18n.t('top_container._singular')}: #{strip_mixed_content(@result.display_string)}"
      @context = [{:uri => @repo_info['top']['uri'], :crumb => @repo_info['top']['name']}, {:uri => nil, :crumb => process_mixed_content(@result.display_string)}]

      # fetch all the objects in this container
      fetch_objects_in_container(uri, params)
    rescue RecordNotFound
      @type = I18n.t('top_container._singular')
      @page_title = I18n.t('errors.error_404', :type => @type)
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found', :status => 404
    end
  end
end
