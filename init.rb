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

require 'redmine'
require 'dispatcher'

Dispatcher.to_prepare do
  require 'redmine_ical/patch_redmine_classes'
end

require_dependency 'redmine_ical/view_hooks'

Redmine::Plugin.register :redmine_ical do
  name 'Redmine Ical Plugin'
  author 'Felix Schäfer (based on work from Frank Schwarz and Jan Schulz-Hofen (Planio))'
  description 'ICalendar view of issue- and version-deadlines'
  version 'thegcat-trunk'
  url 'https://orga.fachschaften.org/projects/redmine_ical'
  author_url 'http://orga.fachschaften.org/users/3'
end


