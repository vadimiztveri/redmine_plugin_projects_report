class GetProjectsSortingBy
  def initialize(projects_and_percents, leader_id)
    @projects_and_percents = projects_and_percents
    @leader_id = leader_id
    @leader_names = get_leader_names
  end

  def run
    {
      percent_asc: get_percent_asc,
      percent_desc: get_percent_desc,
      leaders: get_leaders
    }
  end

  private

  def get_percent_asc
    percent_asc = {}

    @projects_and_percents
      .sort_by{ |key, value| value[:percent].nil? ? 0 : value[:percent] }
      .map do |project|
        project_id = project[0]
        percent = project[1][:percent]
        versions_count = project[1][:versions_count]

        percent_asc[project_id] = {
          percent: percent,
          leader: @leader_names[project_id],
          versions_count: versions_count
        }
      end

    percent_asc
  end

  def get_percent_desc
    percent_desc = {}

    @projects_and_percents
      .sort_by{ |key, value| value[:percent].nil? ? 0 : value[:percent] }
      .reverse!
      .map do |project|
        project_id = project[0]
        percent = project[1][:percent]
        versions_count = project[1][:versions_count]

        percent_desc[project_id] = {
          percent: percent,
          leader: @leader_names[project_id],
          versions_count: versions_count
        }
     end

    percent_desc
  end

  def get_leaders
    leaders = {}

    leaders1 = @leader_names
      .sort_by{ |leader| leader[1] }
      .group_by{ |leader| leader[1] }
      .map do |key, projects|
        leaders[key] = projects.map do |project|
          project_id = project[0]
          versions_count = @projects_and_percents[project_id][:versions_count]

          {
            project_id: project_id,
            versions_count: versions_count
          }
        end
      end

    empty_leader = leaders['']

    if empty_leader.present?
      leaders.delete('')
      leaders[''] = empty_leader
    end

    leaders
  end

  def get_leader_names
    leader_names = {}

    @projects_and_percents.each do |key, value|
      leader_names[key] = get_leader_name(key)
    end

    leader_names
  end

  def get_leader_name(project_id)
    project = Project.find(project_id)
    leader_id = project.custom_value_for(@leader_id).value
    return '' if leader_id.blank?

    leader = CustomField.find(@leader_id).enumerations.where(id: leader_id).take
    return '' if leader.nil?

    leader.name
  end
end
