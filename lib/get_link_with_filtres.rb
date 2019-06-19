class GetLinkWithFiltres
  def initialize(status_ids, title, versions_size, closed_versions_size, project, version, base_event_id, event_id, show_data)
    @status_ids           = status_ids
    @title                = title
    @versions_size        = versions_size
    @closed_versions_size = closed_versions_size
    @project              = project
    @version              = version
    @base_event_id        = base_event_id
    @event_id             = event_id
    @show_data            = show_data
  end

  def run
    return '' unless @show_data

    link = '<a href=/projects/'
    link << @project.identifier

    link << "/issues?set_filter=1"
    link << "&f[]=project_id&op[project_id]==&v[project_id][]="
    link << @project.id.to_s

    if @version.present?
      link << "&f[]=fixed_version_id&op[fixed_version_id]==&v[fixed_version_id][]="
      link << @version.id.to_s
    end

    if @version.nil?
      link << "&query[group_by]=fixed_version"
    end

    link << "&f[]=cf_#{@base_event_id}&op[cf_#{@base_event_id}]==&v[cf_#{@base_event_id}][]="
    link << @event_id.to_s

    link << "&f[]=status_id&op[status_id]=="
    @status_ids.each do |status_id|
      link << "&v[status_id][]="
      link << status_id.to_s
    end

    link << " title='"
    link << @title
    link << "' target='_blank'>"
    if @version.nil?
      link << @closed_versions_size.to_s
      link << ' / '
      link << @versions_size.to_s
    end
    link << '</a>'

    link.html_safe
  end
end
