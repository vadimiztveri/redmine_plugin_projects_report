class GetIssuesLink
  def initialize(base_event_id, project, version, event, issues)
    @base_event_id = base_event_id
    @project       = project
    @version       = version
    @event         = event
    @issues        = issues

    @status_new_id      = Setting.plugin_projects_reports[:status_new_id].to_i
    @status_complete_id = Setting.plugin_projects_reports[:status_complete_id].to_i
    @status_in_work_id  = Setting.plugin_projects_reports[:status_in_work_id].to_i
    @status_returned_id = Setting.plugin_projects_reports[:status_returned_id].to_i
    @status_closed_id   = Setting.plugin_projects_reports[:status_closed_id].to_i

    status_new_name = IssueStatus.find(@status_new_id).name
    @title_red      = get_title_with_one_status(status_new_name)

    status_complete_name = IssueStatus.find(@status_complete_id).name
    status_in_work_name  = IssueStatus.find(@status_in_work_id).name
    status_returned_name = IssueStatus.find(@status_returned_id).name
    @title_yellow        = get_title_with_some_statuses([status_complete_name, status_in_work_name, status_returned_name])

    @title_green = I18n.t('projects_reports.title.green')
  end

  def run
    must_begin_issues = @issues.select{ |issue| issue.start_date.nil? || issue.start_date < Date.current }
    must_begin_count = must_begin_issues.size
    closed_count = must_begin_issues.select{ |issue| issue.status.id == @status_closed_id }.size

    issues_data = {
      issues: '',
      color: 'white'
    }

    if @issues.empty?
      issues_data

    elsif has_new_issues?
      selected_issues = @issues.select{ |issue| issue.start_date.nil? || issue.status.id == @status_new_id }
      issues_data[:issues] = get_link_fith_filters([@status_new_id], @title_red, must_begin_count, closed_count)
      issues_data[:color] = 'red'
      issues_data

    elsif all_issues_complete?
      issues_data[:issues] = get_link_fith_filters([@status_closed_id], @title_green, must_begin_count, closed_count)
      issues_data[:color] = 'green'
      issues_data

    elsif has_issues_in_work?
      selected_issues = @issues.select{ |issue| issue.status.id == @status_in_work_id || issue.status.id == @status_complete_id || issue.status.id == @status_returned_id }
      issues_data[:issues] = get_link_fith_filters([@status_in_work_id, @status_complete_id, @status_returned_id], @title_yellow, must_begin_count, closed_count)
      issues_data[:color] = 'yellow'
      issues_data

    else
      issues_data
    end
  end

  private

  def has_new_issues?
    @issues.select{ |issue| issue.start_date.nil? || issue.status.id == @status_new_id }.any?
  end

  def all_issues_complete?
    @issues.size == @issues.select{ |issue| issue.status.id == @status_closed_id }.size
  end

  def has_issues_in_work?
    @issues.select{ |issue| issue.status.id == @status_in_work_id || issue.status.id == @status_complete_id || issue.status.id == @status_returned_id }.any?
  end

  def get_title_with_one_status(status_name)
    I18n.t('projects_reports.title.some', status_names: "«#{status_name}»")
  end

  def get_title_with_some_statuses(status_names)
    status_names.map!{ |name| "«#{name}»" }
    names_string = status_names[0, status_names.size - 1].join(', ')
    names_string << " или #{status_names[-1]}"

    I18n.t('projects_reports.title.some', status_names: names_string)
  end

  def get_link_fith_filters(status_ids, title, must_begin_count, closed_count)
    GetLinkWithFiltres.new(status_ids, title, must_begin_count, closed_count, @project, @version, @base_event_id, @event.id, true).run
  end
end
