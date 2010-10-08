require_dependency 'calendars_controller'
require_dependency 'issue'

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
            #@events += @query.versions(:conditions => ["effective_date >= ?", three_months_ago])
          end
          cal = Icalendar::Calendar.new
          cal.product_id = "+//IDN fachschaften.org//redmine_ical//EN"
          html_title(@query.new_record? ? l(:label_calendar) : @query.name) # tricks redmine into outputting a pretty title on next call of html_title 
          cal.custom_property("X-WR-CALNAME;VALUE=TEXT", html_title)
          cal.add(@events.to_ical)
          cal.to_ical
        end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          unloadable
          alias_method_chain :show, :ical
          include ApplicationHelper
        end
      end
    end
    
    module Issue
      module ClassMethods
      end
      
      module InstanceMethods
        def to_ical
          return unless due_date
          ical_event = Icalendar::Event.new
          ical_event.summary = "#{project.name} - #{tracker.name} ##{id}: #{subject}"
          ical_event.description = description
          ical_event.created = created_on
          ical_event.start = due_date
          ical_event.end = due_date + 1
          ical_event.uid = "redmine:issue-#{id}@#{Setting.app_title}" # unique ID, needs to stay the same for a given object
          ical_event.category = category.name if category
          #ical_event.url = url_for(:controller => "issues", :action => "show", :id => id, :only_path => false)
          ical_event.to_ical
        end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          unloadable
          include ActionView::Helpers::UrlHelper
        end
      end
    end
  end
end

CalendarsController.send(:include, ::Plugin::Ical::CalendarsController)
Issue.send(:include, ::Plugin::Ical::Issue)