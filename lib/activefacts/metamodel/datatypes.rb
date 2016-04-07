#
#       ActiveFacts Vocabulary Metamodel.
#       Data type support for the Metamodel
#
# Copyright (c) 2016 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  module Metamodel
    class DataType
      TypeNames = %w{
        Boolean
        Integer
        Real
        Decimal
        Money
        Char
        String
        Text
        Date
        Time
        DateTime
        Timestamp
        Binary
      }

      TypeNames.each_with_index do |name, i|
        DataType.const_set("TYPE_"+name, i)
      end

      # Alternate names are case-insensitive, and underscore can be literal, or correspond to a space or to nothing
      AlternateNames = {
        TYPE_Boolean =>
          %w{ bit },
        TYPE_Integer =>
          %w{ auto_counter int tiny_int small_int big_int unsigned unsigned_int unsigned_integer signed_int signed_integer},
        TYPE_Real =>
          %w{ float double },
        TYPE_Decimal =>
          %w{ },
        TYPE_Money =>
          %w{ currency },
        TYPE_Char =>
          %w{ character nchar national_character fixed_length_text },
        TYPE_String =>
          %w{ varchar nvarchar national_character_varying variable_length_text },
        TYPE_Text =>
          %w{ large_length_text },
        TYPE_Date =>
          %w{ },
        TYPE_Time =>
          %w{ },
        TYPE_DateTime =>
          %w{ date_time },
        TYPE_Timestamp =>
          %w{ time_stamp auto_time_stamp },
        TYPE_Binary =>
          %w{ guid picture_raw_data variable_length_raw_data },
      }
      TypeParameters = {
        TYPE_Integer => [:length],            # Length is the number of bits
        TYPE_Real => [:length],               # Length is the number of bits in the mantissa
        TYPE_Decimal => [:precision, :scale], # Precision is the number of significant digits
        TYPE_Money => [:precision, :scale],   # Precision is the number of significant digits. Scale is the digits of fractional cents.
        TYPE_Char => [:length, :charset],     # Charset is e.g. ascii, latin1, iso8859-1, unicode
        TYPE_String => [:length, :charset],
        TYPE_Text => [:charset],
        TYPE_Binary => [:length, :charset],
      }

      # A DataType Context class should refine this class.
      # The default context might work for you.
      class Context
        def integer_ranges
        end

        def default_length data_type, type_name
        end

        def choose_integer_type min, max
          integer_ranges.detect{|type_name, vmin, vmax, bits| min >= vmin && max <= vmax}
        end
      end

      class DefaultContext < Context
        def integer_ranges
          # A set suitable for Standard SQL:
          [
            ['SMALLINT', -2**15, 2**15-1, 16],  # The SQL standard says -10^5..10^5 (less than 16 bits)
            ['INTEGER', -2**31, 2**31-1, 32],   # The standard says -10^10..10^10 (more than 32 bits!)
            ['BIGINT', -2**63, 2**63-1, 64],    # The standard says -10^19..10^19 (less than 64 bits)
          ]
        end

        def default_length data_type, type_name
          case data_type
          when TYPE_Real
            53        # IEEE Double precision floating point
          when TYPE_Integer
            case type_name
            when /([a-z ]|\b)Tiny([a-z ]|\b)/i
              8
            when /([a-z ]|\b)Small([a-z ]|\b)/i,
              /([a-z ]|\b)Short([a-z ]|\b)/i
              16
            when /([a-z ]|\b)Big([a-z ]|\b)/i,
              64
            else
              32
            end
          else
            nil
          end
        end
      end

      def self.normalise type_name
        data_type, = type_mapping.detect{|t, names| names.detect{|n| n === type_name}}
        data_type
      end

      def self.normalise_int_length type_name, length = nil, value_constraint = nil, context = DefaultContext.new
        int_length = length || context.default_length(TYPE_Integer, type_name)
        if int_length
          if value_constraint
            # Pick out the largest maximum and smallest minimum from the ValueConstraint:
            ranges = value_constraint.all_allowed_range_sorted.flat_map{|ar| ar.value_range}
            min = ranges.map(&:minimum_bound).compact.map{|minb| minb.is_inclusive ? minb.value : minb.value-1}.map{|v| v.literal.to_i}.sort[0]
            max = ranges.map(&:maximum_bound).compact.map{|maxb| maxb.is_inclusive ? maxb.value : maxb.value+1}.map{|v| v.literal.to_i}.sort[-1]
          end

          unsigned = type_name =~ /^unsigned/i
          int_min = unsigned ? 0 : -2**(int_length-1)+1
          min = int_min if !min || length && int_min < min
          # SQL does not have unsigned types.
          # Don't force the next largest type just because the app calls for unsigned:
          int_max = unsigned ? 2**(int_length-1) - 1 : 2**(int_length-1)-1
          max = int_max if !max || length && int_max < max
        end
        best = context.choose_integer_type(min, max)
        # Use a context-defined integer size if one suits, otherwise the requested size:
        best && [best[0], best[3]] || length
      end

    private
      def self.type_mapping
        if DataType.const_defined?("TypeMapping")
          return TypeMapping
        end
        DataType.const_set("TypeMapping",
          AlternateNames.inject({}) do |h, (t, a)|
            h[t] = [TypeNames[t]]
            a.each do |n|
              h[t] << /^#{n.gsub(/_/, '[ _]?')}$/i
            end
            h
          end
        )
        TypeMapping
      end

    end
  end
end

if $0 == __FILE__
  D = ActiveFacts::Metamodel::DataType
  D.normalise('Auto Timestamp')

  class ModContext < D::DefaultContext
    def integer_ranges
      [
        ['BIT', 0, 1, 1], 
        ['TINYINT', -2**7, 2**7-1, 8],
      ] +
      super 
    end
  end
  puts "Normalising a tiny"
  p D.normalise_int_length('tiny', nil, nil, ModContext.new)
end
