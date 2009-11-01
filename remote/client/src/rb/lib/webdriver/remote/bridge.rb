module WebDriver
  module Remote
    DEBUG = $VERBOSE == true

    COMMANDS = {}

    #
    # Low level bridge to the remote server, through which the rest of the API works.
    #
    # @api private
    #

    class Bridge
      include Find
      include BridgeHelper

      DEFAULT_OPTIONS = {
        :server_url           => "http://localhost:7055/",
        :http_client          => DefaultHttpClient,
        :desired_capabilities => Capabilities.firefox
      }

      #
      # Defines a wrapper method for a command, which ultimately calls #execute.
      #
      # @param name [Symbol]
      #   name of the resulting method
      # @param url [String]
      #   a URL template, which can include some arguments, much like the definitions on the server.
      #   the :session_id and :context parameters are implicitly handled, but the remainder will become
      #   required method arguments.
      #   e.g., "session/:session_id/:context/element/:id/text" will define a method that takes id
      #   as it's first argument.
      # @param verb [Symbol]
      #   the appropriate http verb, such as :get, :post, or :delete
      #

      def self.command(name, verb, url)
        COMMANDS[name] = [verb, url.freeze]
      end

      attr_accessor :context, :http
      attr_reader :capabilities

      #
      # Initializes the bridge with the given server URL.
      #
      # @param server_url [String] base URL for all commands.  FIXME: Note that a trailing '/' is very important!
      #

      def initialize(opts = {})
        opts          = DEFAULT_OPTIONS.merge(opts)
        @context      = "context"
        @http         = opts[:http_client].new URI.parse(opts[:server_url])
        @capabilities = create_session opts[:desired_capabilities]
      end

      def browser
        @browser ||= @capabilities.browser_name.gsub(" ", "_").to_sym
      end

      #
      # Returns the current session ID.
      #

      def session_id
        @session_id || raise(StandardError, "no current session exists")
      end


      def create_session(desired_capabilities)
        resp  = raw_execute :newSession, {}, desired_capabilities
        @session_id = resp['sessionId'] || raise('no sessionId in returned payload')
        Capabilities.json_create resp['value']
      end

      def get(url)
        execute :get, {}, url
      end

      def goBack
        execute :goBack
      end

      def goForward
        execute :goForward
      end

      def getCurrentUrl
        execute :getCurrentUrl
      end

      def getTitle
        execute :getTitle
      end

      def getPageSource
        execute :getPageSource
      end

      def getVisible
        execute :getVisible
      end

      def setVisible(bool)
        execute :setVisible, {}, bool
      end

      def switchToWindow(name)
        execute :switchToWindow, :name => name
      end

      def switchToFrame(id)
        execute :switchToFrame, :id => id
      end

      def quit
        execute :quit
      end

      def close
        execute :close
      end

      def refresh
        execute :refresh
      end

      def getWindowHandles
        execute :getWindowHandles
      end

      def getCurrentWindowHandle
        execute :getCurrentWindowHandle
      end

      def setSpeed(value)
        execute :setSpeed, {}, value
      end

      def getSpeed
        execute :getSpeed
      end

      def executeScript(script, *args)
        raise UnsupportedOperationError, "underlying webdriver instace does not support javascript" unless capabilities.javascript?

        typed_args = args.map { |arg| wrap_script_argument(arg) }
        response   = raw_execute :executeScript, {}, script, typed_args

        unwrap_script_argument response['value']
      end

      def addCookie(cookie)
        execute :addCookie, {}, cookie
      end

      def deleteCookie(name)
        execute :deleteCookie, :name => name
      end

      def getAllCookies
        execute :getAllCookies
      end

      def deleteAllCookies
        execute :deleteAllCookies
      end

      def findElementByClassName(parent, class_name)
        find_element_by 'class name', class_name, parent
      end

      def findElementsByClassName(parent, class_name)
        find_elements_by 'class name', class_name, parent
      end

      def findElementById(parent, id)
        find_element_by 'id', id, parent
      end

      def findElementsById(parent, id)
        find_elements_by 'id', id, parent
      end

      def findElementByLinkText(parent, link_text)
        find_element_by 'link text', link_text, parent
      end

      def findElementsByLinkText(parent, link_text)
        find_elements_by 'link text', link_text, parent
      end

      def findElementByPartialLinkText(parent, link_text)
        find_element_by 'partial link text', link_text, parent
      end

      def findElementsByPartialLinkText(parent, link_text)
        find_elements_by 'partial link text', link_text, parent
      end

      def findElementByName(parent, name)
        find_element_by 'name', name, parent
      end

      def findElementsByName(parent, name)
        find_elements_by 'name', name, parent
      end

      def findElementByTagName(parent, tag_name)
        find_element_by 'tag name', tag_name, parent
      end

      def findElementsByTagName(parent, tag_name)
        find_elements_by 'tag name', tag_name, parent
      end

      def findElementByXpath(parent, xpath)
        find_element_by 'xpath', xpath, parent
      end

      def findElementsByXpath(parent, xpath)
        find_elements_by 'xpath', xpath, parent
      end


      #
      # Element functions
      #

      def clickElement(element)
        execute :clickElement, :id => element
      end

      def getElementTagName(element)
        execute :getElementTagName, :id => element
      end

      def getElementAttribute(element, name)
        execute :getElementAttribute, :id => element, :name => name
      end

      def getElementValue(element)
        execute :getElementValue, :id => element
      end

      def getElementText(element)
        execute :getElementText, :id => element
      end

      def getElementLocation(element)
        data = execute :getElementLocation, :id => element

        Point.new data['x'], data['y']
      end

      def getElementSize(element)
        execute :getElementSize, :id => element
      end

      def sendKeysToElement(element, string)
        execute :sendKeysToElement, {:id => element}, {:value => string.split(//u)}
      end

      def clearElement(element)
        execute :clearElement, :id => element
      end

      def isElementEnabled(element)
        execute :isElementEnabled, :id => element
      end

      def isElementSelected(element)
        execute :isElementSelected, :id => element
      end

      def isElementDisplayed(element)
        execute :isElementDisplayed, :id => element
      end

      def submitElement(element)
        execute :submitElement, :id => element
      end

      def toggleElement(element)
        execute :toggleElement, :id => element
      end

      def setElementSelected(element)
        execute :setElementSelected, :id => element
      end

      def getElementValueOfCssProperty(element, prop)
        execute :getElementValueOfCssProperty, :id => element, :property_name => prop
      end

      def getActiveElement
        Element.new self, element_id_from(execute(:getActiveElement))
      end
      alias_method :switchToActiveElement, :getActiveElement

      def hoverOverElement
        execute :hoverOverElement, :id => element
      end

      def dragElement(element, rigth_by, down_by)
        # TODO: why is element sent twice in the payload?
        execute :dragElement, {:id => element}, element, rigth_by, down_by
      end

      private

      def find_element_by(how, what, parent = nil)
        if parent
          # TODO: why is how sent twice in the payload?
          id = execute :findChildElement, {:id => parent, :using => how}, {:using => how, :value => what}
        else
          id = execute :findElement, {}, how, what
        end

        Element.new self, element_id_from(id)
      end

      def find_elements_by(how, what, parent = nil)
        if parent
          # TODO: why is how sent twice in the payload?
          ids = execute :findChildElements, {:id => parent, :using => how}, {:using => how, :value => what}
        else
          ids = execute :findElements, {}, how, what
        end

        ids.map { |id| Element.new self, element_id_from(id) }
      end


      #
      # executes a command on the remote server via the REST / JSON API.
      #
      #
      # Returns the 'value' of the returned payload
      #

      def execute(*args)
        raw_execute(*args)['value']
      end

      #
      # executes a command on the remote server via the REST / JSON API.
      #
      # Returns a WebDriver::Remote::Response instance
      #

      def raw_execute(command, opts = {}, *args)
        verb, path = COMMANDS[command] || raise("Unknown command #{command.inspect}")
        path       = path.dup

        path[':session_id'] = @session_id if path.include?(":session_id")
        path[':context']    = @context if path.include?(":context")

        begin
          opts.each { |key, value| path[key.inspect] = value }
        rescue IndexError
          raise ArgumentError, "#{opts.inspect} invalid for #{command.inspect}"
        end

        puts "-> #{verb.to_s.upcase} #{path}" if DEBUG
        http.call verb, path, *args
      end

    end # Bridge
  end # Remote
end # WebDriver
