class ProjectsWithCounts
  def initialize(base_event_id, tracker_id, leader_id, projects)
    @projects      = projects
    @base_event_id = base_event_id
    @tracker_id    = tracker_id
    @leader_id     = leader_id

    status_new_id      = Setting.plugin_projects_reports[:status_new_id].to_i
    status_complete_id = Setting.plugin_projects_reports[:status_complete_id].to_i
    status_in_work_id  = Setting.plugin_projects_reports[:status_in_work_id].to_i
    status_returned_id = Setting.plugin_projects_reports[:status_returned_id].to_i
    status_closed_id   = Setting.plugin_projects_reports[:status_closed_id].to_i
    @all_statuses = [status_new_id, status_complete_id, status_in_work_id, status_returned_id, status_closed_id]

    @events = CustomField.find(base_event_id).enumerations.active.order(:position)
    @events_ids = @events.map(&:id)
  end

  def run
    projects = {}

    @projects.each_with_index do |project|
      versions = get_versions(project)
      versions_count = versions.size + 1
      issues_count = versions.map{ |varsion| varsion[:issue_count] }.sum

      if issues_count > 0
        projects[project.id] = {
          name_with_link: name_with_link(project),
          versions_count: versions_count,
          versions_header: get_versions_header(project, versions),
          versions: versions,
          issues_count: issues_count
        }
      end
    end

    projects
  end

  private

  def get_versions(project)
    versions = []

    project.versions.open.to_a.sort_by{ |v| v.name }.each do |version|
      project_issues = Issue.find_by_sql("
        SELECT
          id, status_id, start_date
        FROM
          issues
        WHERE
          project_id = #{project.id}
            and tracker_id = #{@tracker_id}
            and fixed_version_id = #{version.id}
            and (start_date IS NULL or start_date < CURDATE())
        ;
      ")

      if project_issues.any?
        events = get_events(project, version, project_issues)

        colors = @events_ids.map{ |event_id| events[event_id][:color] }
        closed_events_size = colors.count('green')
        events_size = @events_ids.size

        average_percent = get_average_percent(events_size, closed_events_size)
        color = get_color(average_percent)

        version_data = {
          name: version_with_link(version),
          percent: average_percent,
          color: color,
          events: events,
          header: false,
          issue_count: project_issues.size
        }

        versions << version_data
      end
    end

    versions
  end

  def get_versions_header(project, versions)
    events_header = get_events_header(project, versions)

    closed_versions_size_sum = @events_ids.map{ |event_id| events_header[event_id][:closed_versions_size] }.sum
    versions_size_sum = @events_ids.map{ |event_id| events_header[event_id][:versions_size] }.sum
    average_percent = get_average_percent(versions_size_sum, closed_versions_size_sum)

    {
      name: '',
      percent: average_percent,
      color: get_color(average_percent),
      events: events_header,
      header: true
    }
  end

  def get_events_header(project, versions)
    events = {}

    @events_ids.map do |event_id|
      colors = versions.map{ |version| version[:events][event_id][:color] }

      closed_versions_size = colors.count('green')
      versions_size = versions.size

      color = get_background_color(colors)

      events[event_id] = {
        closed_versions_size: closed_versions_size,
        versions_size: versions_size,
        issues: get_issues_for_event_header(versions_size, closed_versions_size, project, event_id, color),
        color: get_background_color(colors),

        percent: true
      }
    end

    events
  end

  def get_issues_for_event_header(versions_size, closed_count, project, event_id, color)
    show_data = (color != 'white')
    GetLinkWithFiltres.new(@all_statuses, 'Просмотр задач', versions_size, closed_count, project, nil, @base_event_id, event_id, show_data).run
  end

  def get_events(project, version, issues)
    events = {}
    issues_ids = issues.map(&:id)

    @events.each do |event|
      if issues_ids.empty?
        events[event.id] = { issues: "", color: "white" }
      else
        condition = "customized_type = 'Issue'"
        condition << " and custom_field_id = #{@base_event_id}"
        condition << " and value = #{event.id}"
        conditions = issues_ids.map{ |id| "customized_id = #{id}" }.join(' or ')
        condition << " and (#{conditions})"

        custom_values = CustomValue.find_by_sql("
          SELECT
            customized_id
          FROM
            custom_values
          WHERE
            #{condition}
          ;
        ")

        custom_values_ids = custom_values.map(&:customized_id)
        issues_with_events = issues.select{ |issue| custom_values_ids.include?(issue.id) }

        events[event.id] = get_issues(project, version, event, issues_with_events)
      end
    end

    events
  end

  def get_issues(project, version, event, issues)
    GetIssuesLink.new(@base_event_id, project, version, event, issues).run
  end

  def name_with_link(project)
    "<a href='/projects/#{project.id}' target='blank'>#{project.name}</a>".html_safe
  end

  def version_with_link(version)
    "<a href='/versions/#{version.id}' target='blank'>#{version.name}</a>".html_safe
  end

  def get_average_percent(must_begin_count_sum, closed_count_sum)
    if must_begin_count_sum == 0
      nil
    else
      ((closed_count_sum.to_f / must_begin_count_sum.to_f) * 100).to_i
    end
  end

  def get_color(average_percent)
    if average_percent.nil?
      'white'
    elsif average_percent > 80
      'green'
    elsif average_percent > 50
      'yellow'
    else
      'red'
    end
  end

  def get_background_color(colors)
    if colors.include?('red')
      'red'
    elsif colors.include?('yellow')
      'yellow'
    elsif colors.include?('green')
      'green'
    else
      'white'
    end
  end
end
