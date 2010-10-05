# redmics - redmine icalendar export plugin
# Copyright (c) 2010  Frank Schwarz, frank.schwarz@buschmais.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'icalendar'

class ICalendarController < ApplicationController
  before_filter :find_project
  accept_key_auth :index
  
  def index
    # project
    ids = [@project.id] + @project.descendants.collect(&:id)
    project_condition = ["#{Project.table_name}.id IN (?)", ids]
    
    # issue status
    case params[:status]
    when 'all'
      status_condition = []
    when 'open'
      status_condition = ["#{IssueStatus.table_name}.is_closed = ?", false]
    else
      status_condition = nil
    end
    
    # assignment
    case params[:assigned_to]
    when 'me'
      assigned_to_condition = ["assigned_to_id = #{User.current.id}"]
    when '+'
      assigned_to_condition = ["assigned_to_id is not null"]
    when '*'
      assigned_to_condition = []
    else
    end
    
    events = []
    # queries
    unless status_condition.nil? || assigned_to_condition.nil?
      c = ARCondition.new(project_condition)
      c << status_condition      unless status_condition.empty?
      c << assigned_to_condition unless assigned_to_condition.empty?
      events += Issue.find(
        :all, 
        :include => [:tracker, :assigned_to, :priority, :project, :status, :fixed_version, :author], 
        :conditions => c.conditions
        )
      end
      events += Version.find(
        :all,
        :include => [:project], 
        :conditions => project_condition
      )
    
    @cal_string = create_calendar(events).to_ical
    send_data @cal_string, :type => Mime::ICS, :filename => 'issues.ics'
  end

private
  
  def find_project
    @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def create_calendar(events)
    cal = Icalendar::Calendar.new
    events.each { |i| 
      if (i.due_date == nil) && (i.is_a? Issue) && (i.fixed_version != nil)
        i.due_date = i.fixed_version.due_date
      end
      if i.due_date == nil
        next
      end
      event = Icalendar::Event.new
      event.dtstart        i.due_date, {'VALUE' => 'DATE'}
      event.dtend          i.due_date + 1, {'VALUE' => 'DATE'}
      if i.is_a? Issue
        event.summary      "#{i.subject} (#{i.status.name})"
        event.url          url_for(:controller => 'issues', :action => 'show', :id => i.id, :project_id => i.project_id)
        unless i.fixed_version.nil?
          event.categories   [i.fixed_version.name]
        end
        unless i.assigned_to.nil?
          event.add_contact  i.assigned_to.name, {"ALTREP" => i.assigned_to.mail}
        end
        event.organizer    "mailto:#{i.author.mail}", {"CN" => i.author.name}
        event.status       i.assigned_to == nil ? "TENTATIVE" : "CONFIRMED"
        event.created      i.created_on.to_date, {'VALUE' => 'DATE'}
      elsif i.is_a? Version
        event.summary      "%s '#{i.name}'" % l(:label_calendar_deadline)
        event.url          url_for(:controller => 'versions', :action => 'show', :id => i.id)
      else
      end
      unless i.description.nil?
        event.description = i.description
      end
      cal.add_event(event)
    }
    return cal
  end

end

