# redmine_ical
# Copyright (c) 2010  Frank Schwarz, frank.schwarz@buschmais.com,
# Jan Schulz-Hofen (Planio), jan@plan.io
# Felix Schäfer, felix@fachschaften.org
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

require_dependency 'calendars_controller'
require_dependency 'issue'
require_dependency 'version'

require 'icalendar'

module Plugin
  module Ical
    module CalendarsController
      module ClassMethods

      end

      module InstanceMethods
        def show_with_ical
          respond_to do |format|
            format.html { show_without_ical }
            format.ics { render :text => ical, :layout => false }
          end
        end

        def ical
          # retrieve events 3 months old or newer
          retrieve_query
          @query.group_by = nil
          @events = []
          three_months_ago = 3.months.ago
          if @query.valid?
            @events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                                     :conditions => ["((start_date >= ?) OR (due_date >= ?))", three_months_ago, three_months_ago])
            @events += @query.versions(:conditions => ["effective_date >= ?", three_months_ago])
          end
          cal = Icalendar::Calendar.new
          cal.product_id = "+//IDN fachschaften.org//redmine_ical//EN"
          html_title(@query.new_record? ? l(:label_calendar) : @query.name) # tricks redmine into outputting a pretty title on next call of html_title
          cal.custom_property("X-WR-CALNAME;VALUE=TEXT", html_title)
          @events.each do |event|
            e = event.to_ical_hash
            next unless e
            e[:url] = url_for(:controller => e[:type].to_s.pluralize, :action => 'show', :id => e[:id], :only_path => false)
            cal.event do
              summary       e[:summary]
              description   "#{e[:description]}\n\n#{e[:url]}"
              created       e[:created].to_datetime
              last_modified e[:updated].to_datetime
              dtstart       e[:date], {"VALUE" => ["DATE"]}
              dtend         e[:date]+1, {"VALUE" => ["DATE"]}
              uid           "redmine:#{e[:type].to_s}-#{e[:id]}@#{defined?(request) ? request.host : ::Socket.gethostname}"
              url           e[:url]
            end
          end
          cal.to_ical
        end
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          unloadable
          include ApplicationHelper
          alias_method_chain :show, :ical
          accept_api_auth :show
        end
      end
    end

    module Issue
      module ClassMethods
      end

      module InstanceMethods
        def to_ical_hash
          date = due_date
          date ||= fixed_version.due_date if fixed_version
          return unless date
          {:summary => "#{project.name} - #{tracker.name} ##{id}: #{subject}",
           :description => description,
           :created => created_on,
           :updated => updated_on,
           :date => date,
           :type => :issue,
           :id => id
           }
        end
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          unloadable
        end
      end
    end

    module Version
      module ClassMethods
      end

      module InstanceMethods
        def to_ical_hash
          return unless due_date
          {:summary => "#{project.name} - #{name}",
           :description => description,
           :created => created_on,
           :updated => updated_on,
           :date => due_date,
           :type => :version,
           :id => id
           }
        end
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          unloadable
        end
      end
    end
  end
end