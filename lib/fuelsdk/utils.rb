module FuelSDK
  module_function

    def format_name_value_pairs attributes
      attrs = []
      attributes.each do |name, value|
        attrs.push 'Name' => name, 'Value' => value
      end

      attrs
    end

    def format_props attributes
      attributes.map do |property_value_pair|
        name, value = property_value_pair

        if value.nil?
          { '@xsi:type' => "tns:NullAPIProperty", 'Name' => name }
        else
          { 'Name' => name, 'Value' => value }
        end
      end
    end

    def schoff(obj, pre=' ', pad=nil, cr=true)
      case obj
        when Array
          print "#{pre if pad.nil?}#{pad}["
          ct = obj.size - 1
          obj.each_with_index{ |o, idx|
            schoff(o, pre, ' ', cr=false)
            print "#{',' unless idx >= ct}"
          }
          print ' ]'
        when Hash
          keys = obj.keys
          len = keys.map(&:length).max
          ct = keys.count
          idx = 0
          print "#{pre if pad.nil?}#{pad}{"
          print "\n" unless ct == 1

          obj.each{ |k,v|
            idx +=1
            print "#{pre} " unless ct == 1
            print " :#{k}#{' '*(len-k.length)} =>"
            schoff(v, "#{pre}  ", ' ', false)
            print "#{',' unless idx == ct}"
            print "\n" unless ct == 1
          }
          print "#{pre}" unless ct == 1
          print '}'
        when nil
          print "#{pre if pad.nil?}#{pad}nil"
        when String
          print "#{pre if pad.nil?}#{pad}\"#{obj}\""
        else
          print "#{pre if pad.nil?}#{pad}#{obj}"
      end
      print "\n" if cr
    end
end
