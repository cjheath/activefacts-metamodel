#
#       ActiveFacts Vocabulary Metamodel.
#       Extensions to the ActiveFacts Vocabulary classes (which are generated from the Metamodel)
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/support'

module ActiveFacts
  module Metamodel
    class Vocabulary
      def finalise
        constellation.FactType.values.each do |fact_type|
          if c = fact_type.check_and_add_spanning_uniqueness_constraint
            trace :constraint, "Checking for existence of at least one uniqueness constraint over the roles of #{fact_type.default_reading.inspect}"
            fact_type.check_and_add_spanning_uniqueness_constraint = nil
            c.call
          end
        end
      end

      # This name does not yet exist (at least not as we expect it to).
      # If it in fact does exist (but as the wrong type), complain.
      # If it doesn't exist, but its name would cause existing fact type
      # readings to be re-interpreted to a different meaning, complain.
      # Otherwise return nil.
      def check_valid_nonexistent_object_type_name name
        if ot = valid_object_type_name(name)
          raise "Cannot redefine #{ot.class.basename} #{name}"
        end
      end

      def valid_object_type_name name
        # Raise an exception if adding this name to the vocabulary would create anomalies
        anomaly = constellation.Reading.detect do |r_key, reading|
            expanded = reading.expand do |role_ref, *words|
                words.map! do |w|
                  case
                  when w == nil
                    w
                  when w[0...name.size] == name
                    '_ok_'+w
                  when w[-name.size..-1] == name
                    w[-1]+'_ok_'
                  else
                    w
                  end
                end

                words
              end
            expanded =~ %r{\b#{name}\b}
          end
        raise "Adding new term '#{name}' would create anomalous re-interpretation of '#{anomaly.expand}'" if anomaly
        @constellation.ObjectType[[identifying_role_values, name]]
      end

      # If this entity type exists, ok, otherwise check it's ok to add it
      def valid_entity_type_name name
        @constellation.EntityType[[identifying_role_values, name]] or
          check_valid_nonexistent_object_type_name name
      end

      # If this entity type exists, ok, otherwise check it's ok to add it
      def valid_value_type_name name
        @constellation.ValueType[[identifying_role_values, name]] or
          check_valid_nonexistent_object_type_name name
      end
    end

    class Concept
      def describe
        case
        when object_type; "#{object_type.class.basename} #{object_type.name.inspect}"
        when fact_type; "FactType #{fact_type.default_reading.inspect}"
        when role; "Role in #{role.fact_type.describe(role)}"
        when constraint; constraint.describe
        when instance; "Instance #{instance.verbalise}"
        when fact; "Fact #{fact.verbalise}"
        when query; query.describe
        when context_note; "ContextNote#{context_note.verbalise}"
        when unit; "Unit #{unit.describe}"
        when population; "Population: #{population.name}"
        else
          raise "ROGUE CONCEPT OF NO TYPE"
        end
      end

      def embodied_as
        case
        when object_type; object_type
        when fact_type; fact_type
        when role; role
        when constraint; constraint
        when instance; instance
        when fact; fact
        when query; query
        when context_note; context_note
        when unit; unit
        when population; population
        else
          raise "ROGUE CONCEPT OF NO TYPE"
        end
      end

      # Return an array of all Concepts that must be defined before this concept can be defined:
      def precursors
        case body = embodied_as
        when ActiveFacts::Metamodel::ValueType
          [ body.supertype, body.unit ] +
          body.all_value_type_parameter.map{|f| f.facet_value_type } +
          body.all_value_type_parameter_restriction.map{|vr| vr.value.unit}
        when ActiveFacts::Metamodel::EntityType
          # You can't define the preferred_identifier fact types until you define the entity type,
          # but the objects which play the identifying roles must be defined:
          body.preferred_identifier.role_sequence.all_role_ref.map {|rr| rr.role.object_type } +
          # You can't define the objectified fact type until you define the entity type:
          # [ body.fact_type ]  # If it's an objectification
          body.all_type_inheritance_as_subtype.map{|ti| ti.supertype}   # If it's a subtype
        when FactType
          body.all_role.map(&:object_type)
        when Role   # We don't consider roles as they cannot be separately defined
          []
        when ActiveFacts::Metamodel::PresenceConstraint
          body.role_sequence.all_role_ref.map do |rr|
            rr.role.fact_type
          end
        when ActiveFacts::Metamodel::ValueConstraint
          [ body.role ? body.role.fact_type : nil, body.value_type ] +
          body.all_allowed_range.map do |ar|
            [ ar.value_range.minimum_bound, ar.value_range.maximum_bound ].compact.map{|b| b.value.unit}
          end
        when ActiveFacts::Metamodel::SubsetConstraint
          body.subset_role_sequence.all_role_ref.map{|rr| rr.role.fact_type } +
          body.superset_role_sequence.all_role_ref.map{|rr| rr.role.fact_type }
        when ActiveFacts::Metamodel::SetComparisonConstraint
          body.all_set_comparison_roles.map{|scr| scr.role_sequence.all_role_ref.map{|rr| rr.role.fact_type } }
        when ActiveFacts::Metamodel::RingConstraint
          [ body.role.fact_type, body.other_role.fact_type ]
        when Instance
          [ body.population, body.object_type, body.value ? body.value.unit : nil ]
        when Fact
          [ body.population, body.fact_type ]
        when Query
          body.all_variable.map do |v|
            [ v.object_type,
              v.value ? v.value.unit : nil,
              v.step ? v.step.fact_type : nil
            ] +
            v.all_play.map{|p| p.role.fact_type }
          end
        when ContextNote
          []
        when Unit
          body.all_derivation_as_derived_unit.map{|d| d.base_unit }
        when Population
          []
        else
          raise "ROGUE CONCEPT OF NO TYPE"
        end.flatten.compact.uniq.map{|c| c.concept }
      end
    end

    class Topic
      def precursors
	# Precursors of a topic are the topics of all precursors of items in this topic
	all_concept.map{|c| c.precursors }.flatten.uniq.map{|c| c.topic}.uniq-[self]
      end
    end

    class Unit
      def describe
        'Unit' +
        name +
        (plural_name ? '/'+plural_name : '') +
        '=' +
        coefficient.to_s+'*' +
        all_derivation_as_derived_unit.map do |derivation|
          derivation.base_unit.name +
          (derivation.exponent != 1 ? derivation.exponent.to_s : '')
        end.join('') +
        (offset ? ' + '+offset.to_s : '')
      end
    end

    class Coefficient
      def to_s
        numerator.to_s +
        (denominator != 1 ? '/' + denominator.to_s : '')
      end
    end

    class FactType
      attr_accessor :check_and_add_spanning_uniqueness_constraint

      def all_reading_by_ordinal
        all_reading.sort_by{|reading| reading.ordinal}
      end

      def preferred_reading negated = false
        pr = all_reading_by_ordinal.detect{|r| !r.is_negative == !negated }
        raise "No reading for (#{all_role.map{|r| r.object_type.name}*", "})" unless pr || negated
        pr
      end

      def describe(highlight = nil)
        (entity_type ? entity_type.name : "")+
        '('+all_role.map{|role| role.describe(highlight) }*", "+')'
      end

      def default_reading(frequency_constraints = [], define_role_names = nil)
        preferred_reading.expand(frequency_constraints, define_role_names)
      end

      # Does any role of this fact type participate in a preferred identifier?
      def is_existential
        return false if all_role.size > 2
        all_role.detect do |role|
          role.all_role_ref.detect do |rr|
            rr.role_sequence.all_presence_constraint.detect do |pc|
              pc.is_preferred_identifier
            end
          end
        end
      end

      def is_unary
	all_role.size == 1
      end

      def internal_presence_constraints
        all_role.map do |r|
          r.all_role_ref.map do |rr|
            !rr.role_sequence.all_role_ref.detect{|rr1| rr1.role.fact_type != self } ?
              rr.role_sequence.all_presence_constraint.to_a :
              []
          end
        end.flatten.compact.uniq
      end

      def reading_preferably_starting_with_role role, negated = false
        all_reading_by_ordinal.detect do |reading|
          reading.text =~ /\{(\d+)\}/ and
            reading.role_sequence.all_role_ref_in_order[$1.to_i].role.base_role == role and
            reading.is_negative == !!negated
        end || preferred_reading(negated)
      end

      def all_role_in_order
        all_role.sort_by{|r| r.ordinal}
      end

      def compatible_readings types_array
        all_reading.select do |reading|
          ok = true
          reading.role_sequence.all_role_ref_in_order.each_with_index do |rr, i|
            ok = false unless types_array[i].include?(rr.role.object_type)
          end
          ok
        end
      end
    end

    class Role
      # Mirror Role defines this, but it's more convenient not to have to type-check.
      # A Role that's not a Mirror Role is its own base role.
      def base_role
	self
      end

      def describe(highlight = nil)
        object_type.name + (self == highlight ? "*" : "")
      end

      def is_mandatory
	return true if fact_type.is_a?(LinkFactType) # Handle objectification roles
        all_role_ref.detect{|rr|
          rs = rr.role_sequence
          rs.all_role_ref.size == 1 and
          rs.all_presence_constraint.detect{|pc|
            pc.min_frequency and pc.min_frequency >= 1 and pc.is_mandatory
          }
        } ? true : false
      end

      def preferred_reference
        fact_type.preferred_reading.role_sequence.all_role_ref.detect{|rr| rr.role == self }
      end

      # Return true if this role is functional (has only one instance wrt its player)
      # A role in an objectified fact type is deemed to refer to the implicit role of the objectification.
      def is_functional
	return true if fact_type.is_a?(LinkFactType) # Handle objectification roles

        fact_type.entity_type or
        fact_type.all_role.size != 2 or
        uniqueness_constraint
      end

      # Find any internal uniqueness constraint on this role only
      def uniqueness_constraint
        base_role.all_role_ref.detect{|rr|
          rs = rr.role_sequence
          rs.all_role_ref.size == 1 and
            rs.all_presence_constraint.detect do |pc|
              return pc if pc.max_frequency == 1 and !pc.enforcement   # Alethic uniqueness constraint
            end
        }
	nil
      end

      def is_identifying
	uc = uniqueness_constraint and uc.is_preferred_identifier
      end

      # Is there are internal uniqueness constraint on this role only?
      def is_unique
	return true if fact_type.is_a?(LinkFactType) or		# Handle objectification roles
	  fact_type.all_role.size == 1				# and unary roles

	uniqueness_constraint ? true : false
      end

      def unique
	raise "REVISIT: unique is deprecated. Call is_unique instead"
      end

      def name
        role_name or
	is_mirror_role && base_role.role_name or
	fact_type.is_unary && unary_name or
	String::Words.new(preferred_reference.role_name nil).capwords*' ' or
	object_type.name
      end

      def unary_name
	fact_type.preferred_reading.text.gsub(/\{[0-9]\}/,'').words.titlewords*' '
      end

      def is_link_role
        fact_type.is_a?(LinkFactType)
      end

      def is_mirror_role
	is_a?(MirrorRole)
      end

      def is_objectification_role
	is_link_role && !is_mirror_role
      end

      def counterpart
	case fact_type.all_role.size
	when 1
	  self
	when 2
	  (fact_type.all_role.to_a-[self])[0]
	else
	  nil # raise "counterpart roles are undefined in n-ary fact types"
	end
      end
    end

    class RoleRef
      def describe
        role_name
      end

      def preferred_reference
        role.preferred_reference
      end

      def role_name(separator = "-")
        return 'UNKNOWN' unless role
        name_array =
          if role.fact_type.all_role.size == 1
            if role.fact_type.is_a?(LinkFactType)
              "#{role.object_type.name} objectification role for #{role.fact_type.role.object_type.name}"
            else
              role.fact_type.preferred_reading.text.gsub(/\{[0-9]\}/,'').strip.split(/\s/)
            end
          else
            role.role_name || [leading_adjective, role.object_type.name, trailing_adjective].compact.map{|w| w.split(/\s/)}.flatten
          end
        return separator ? Array(name_array)*separator : Array(name_array)
      end

      def cql_leading_adjective
	if leading_adjective
	  # 'foo' => "foo-"
	  # 'foo bar' => "foo- bar "
	  # 'foo-bar' => "foo-- bar "
	  # 'foo-bar baz' => "foo-- bar baz "
	  # 'bat foo-bar baz' => "bat- foo-bar baz "
	  leading_adjective.strip.
	    sub(/[- ]|$/, '-\0 ').sub(/  /, ' ').sub(/[^-]$/, '\0 ').sub(/-  $/,'-')
	else
	  ''
	end
      end

      def cql_trailing_adjective
	if trailing_adjective
	  # 'foo' => "-foo"
	  # 'foo bar' => " foo -bar"
	  # 'foo-bar' => " foo --bar"
	  # 'foo-bar baz' => " foo-bar -baz"
	  # 'bat foo-bar baz' => " bat foo-bar -baz"
	  trailing_adjective.
	    strip.
	    sub(/(?<a>.*) (?<b>[^- ]+$)|(?<a>.*)(?<b>-[^- ]*)$|(?<a>)(?<b>.*)/) {
	      " #{$~[:a]} -#{$~[:b]}"
	    }.
	    sub(/^ *-/, '-')  # A leading space is not needed if the hyphen is at the start
	else
	  ''
	end
      end

      def cql_name
        if role.fact_type.all_role.size == 1
          role_name
        elsif role.role_name
          role.role_name
        else
          # Where an adjective has multiple words, the hyphen is inserted outside the outermost space, leaving the space
	  cql_leading_adjective +
            role.object_type.name+
	    cql_trailing_adjective
        end
      end
    end

    class RoleSequence
      def describe(highlighted_role_ref = nil)
        "("+
          all_role_ref.sort_by{|rr| rr.ordinal}.map{|rr| rr.describe + (highlighted_role_ref == rr ? '*' : '') }*", "+
        ")"
      end

      def all_role_ref_in_order
        all_role_ref.sort_by{|rr| rr.ordinal}
      end
    end

    class ObjectType
      # Placeholder for the surrogate transform
      attr_reader :injected_surrogate_role

      def is_separate
	is_independent or concept.all_concept_annotation.detect{|ca| ca.mapping_annotation == 'separate'}
      end

      def all_role_transitive
	supertypes_transitive.flat_map(&:all_role)
      end
    end

    class ValueType
      def supertypes_transitive
        [self] + (supertype ? supertype.supertypes_transitive : [])
      end

      def all_subtype
        all_value_type_as_supertype
      end
      alias_method :subtypes, :all_subtype    # REVISIT: Delete legacy name

      def subtypes_transitive
        [self] + subtypes.map{|st| st.subtypes_transitive}.flatten
      end

      def common_supertype(other)
        return nil unless other.is_?(ActiveFacts::Metamodel::ValueType)
        return self if other.supertypes_transitive.include?(self)
        return other if supertypes_transitive.include(other)
        nil
      end

      # Is this ValueType auto-assigned? Returns either 'assert', 'commit', otherwise nil.
      def is_auto_assigned
        type = self
        while type
          return type.transaction_phase || 'commit' if type.name =~ /^Auto/ || type.transaction_phase
          type = type.supertype
        end
        nil
      end
    end

    class EntityType
      def identification_is_inherited
        preferred_identifier and
          preferred_identifier.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) }
      end

      def assimilation
	ti = identifying_type_inheritance and ti.assimilation
      end

      def is_separate
	super || !['absorbed', nil].include?(assimilation)
      end

      def preferred_identifier
        return @preferred_identifier if @preferred_identifier
        if fact_type
	  # Objectified unaries are identified by the ID of the object that plays the role:
	  if fact_type.all_role.size == 1
	    return @preferred_identifier = fact_type.all_role.single.object_type.preferred_identifier
	  end

          # When compiling a fact instance, the delayed creation of a preferred identifier might be necessary
          if c = fact_type.check_and_add_spanning_uniqueness_constraint
            fact_type.check_and_add_spanning_uniqueness_constraint = nil
            c.call
          end

          # For a nested fact type, the PI is a unique constraint over N or N-1 roles
          fact_roles = Array(fact_type.all_role)
          trace :pi, "Looking for PI on nested fact type #{name}" do
            pi = catch :pi do
                fact_roles[0,2].each{|r|                  # Try the first two roles of the fact type, that's enough
                    r.all_role_ref.map{|rr|               # All role sequences that reference this role
                        role_sequence = rr.role_sequence

                        # The role sequence is only interesting if it cover only this fact's roles
                        # or roles of the objectification
                        next if role_sequence.all_role_ref.size < fact_roles.size-1 # Not enough roles
                        next if role_sequence.all_role_ref.size > fact_roles.size   # Too many roles
                        next if role_sequence.all_role_ref.detect do |rsr|
                            if (of = rsr.role.fact_type) != fact_type
                              case of.all_role.size
                              when 1    # A unary FT must be played by the objectification of this fact type
                                next rsr.role.object_type != fact_type.entity_type
                              when 2    # A binary FT must have the objectification of this FT as the other player
                                other_role = (of.all_role-[rsr.role])[0]
                                next other_role.object_type != fact_type.entity_type
                              else
                                next true # A role in a ternary (or higher) cannot be usd in our identifier
                              end
                            end
                            rsr.role.fact_type != fact_type
                          end

                        # This role sequence is a candidate
                        pc = role_sequence.all_presence_constraint.detect{|c|
                            c.max_frequency == 1 && c.is_preferred_identifier
                          }
                        throw :pi, pc if pc
                      }
                  }
                throw :pi, nil
              end
            trace :pi, "Got PI #{pi.name||pi.object_id} for nested #{name}" if pi
            trace :pi, "Looking for PI on entity that nests this fact" unless pi
            raise "Oops, pi for nested fact is #{pi.class}" unless !pi || pi.is_a?(ActiveFacts::Metamodel::PresenceConstraint)
            return @preferred_identifier = pi if pi
          end
        end

        trace :pi, "Looking for PI for ordinary entity #{name} with #{all_role.size} roles:" do
          trace :pi, "Roles are in fact types #{all_role.map{|r| r.fact_type.describe(r)}*", "}"
          pi = catch :pi do
              all_supertypes = supertypes_transitive
              trace :pi, "PI roles must be played by one of #{all_supertypes.map(&:name)*", "}" if all_supertypes.size > 1
              all_role.each{|role|
                  next unless role.is_unique || fact_type
                  ftroles = Array(role.fact_type.all_role)

                  # Skip roles in ternary and higher fact types, they're objectified
		  # REVISIT: This next line prevents a unary being used as a preferred_identifier:
                  next if ftroles.size != 2

                  trace :pi, "Considering role in #{role.fact_type.describe(role)}"

                  # Find the related role which must be included in any PI:
                  # Note this works with unary fact types:
                  pi_role = ftroles[ftroles[0] != role ? 0 : -1]

                  next if ftroles.size == 2 && pi_role.object_type == self
                  trace :pi, "  Considering #{pi_role.object_type.name} as a PI role"

                  # If this is an identifying role, the PI is a PC whose role_sequence spans the role.
                  # Walk through all role_sequences that span this role, and test each:
                  pi_role.all_role_ref.each{|rr|
                      role_sequence = rr.role_sequence  # A role sequence that includes a possible role

                      trace :pi, "    Considering role sequence #{role_sequence.describe}"

                      # All roles in this role_sequence must be in fact types which
                      # (apart from that role) only have roles played by the original
                      # entity type or a supertype.
                      #trace :pi, "      All supertypes #{all_supertypes.map{|st| "#{st.object_id}=>#{st.name}"}*", "}"
                      if role_sequence.all_role_ref.detect{|rsr|
                          fact_type = rsr.role.fact_type
                          trace :pi, "      Role Sequence touches #{fact_type.describe(pi_role)}"

                          fact_type_roles = fact_type.all_role
                          trace :pi, "      residual is #{fact_type_roles.map{|r| r.object_type.name}.inspect} minus #{rsr.role.object_type.name}"
                          residual_roles = fact_type_roles-[rsr.role]
                          residual_roles.detect{|rfr|
                              trace :pi, "        Checking residual role #{rfr.object_type.object_id}=>#{rfr.object_type.name}"
# This next line looks right, but breaks things. Find out what and why:
#                              !rfr.unique or
                                !all_supertypes.include?(rfr.object_type)
                            }
                        }
                        trace :pi, "      Discounting this role_sequence because it includes alien roles"
                        next
                      end

                      # Any presence constraint over this role sequence is a candidate
                      rr.role_sequence.all_presence_constraint.detect{|pc|
                          # Found it!
                          if pc.is_preferred_identifier
                            trace :pi, "found PI #{pc.name||pc.object_id}, is_preferred_identifier=#{pc.is_preferred_identifier.inspect} over #{pc.role_sequence.describe}"
                            throw :pi, pc
                          end
                        }
                    }
                }
              throw :pi, nil
            end
          raise "Oops, pi for entity is #{pi.class}" if pi && !pi.is_a?(ActiveFacts::Metamodel::PresenceConstraint)
          trace :pi, "Got PI #{pi.name||pi.object_id} for #{name}" if pi

          if !pi
            if (supertype = identifying_supertype)
              # This shouldn't happen now, as an identifying supertype is connected by a fact type
              # that has a uniqueness constraint marked as the preferred identifier.
              #trace :pi, "PI not found for #{name}, looking in supertype #{supertype.name}"
              #pi = supertype.preferred_identifier
              #return nil
            elsif fact_type
              possible_pi = nil
              fact_type.all_role.each{|role|
                role.all_role_ref.each{|role_ref|
                  # Discount role sequences that contain roles not in this fact type:
                  next if role_ref.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type != fact_type }
                  role_ref.role_sequence.all_presence_constraint.each{|pc|
                    next unless pc.max_frequency == 1
                    possible_pi = pc
                    next unless pc.is_preferred_identifier
                    pi = pc
                    break
                  }
                  break if pi
                }
                break if pi
              }
              if !pi && possible_pi
                trace :pi, "Using existing PC as PI for #{name}"
                pi = possible_pi
              end
            else
              trace :pi, "No PI found for #{name}"
              debugger if respond_to?(:debugger)
            end
          end
          raise "No PI found for #{name}" unless pi
          @preferred_identifier = pi
        end
      end

      def preferred_identifier_roles
	preferred_identifier.role_sequence.all_role_ref_in_order.map(&:role)
      end

      def rank_in_preferred_identifier(role)
	preferred_identifier_roles.index(role)
      end

      # An array of all direct subtypes:
      def subtypes
        # REVISIT: There's no sorting here. Should there be?
        all_type_inheritance_as_supertype.map{|ti| ti.subtype }
      end

      def subtypes_transitive
        [self] + subtypes.map{|st| st.subtypes_transitive}.flatten.uniq
      end

      def all_supertype_inheritance
        all_type_inheritance_as_subtype.sort_by{|ti|
            [ti.provides_identification ? 0 : 1, ti.supertype.name]
          }
      end

      # An array of all direct supertypes
      def supertypes
        all_supertype_inheritance.map{|ti|
            ti.supertype
          }
      end

      # An array of all direct subtypes
      def all_subtype
        all_type_inheritance_as_supertype.map(&:subtype)
      end

      # An array of self followed by all supertypes in order:
      def supertypes_transitive
        ([self] + all_type_inheritance_as_subtype.map{|ti|
            ti.supertype.supertypes_transitive
          }).flatten.uniq
      end

      def identifying_type_inheritance
        all_type_inheritance_as_subtype.detect do |ti|
	  ti.provides_identification
	end
      end

      # A subtype does not have a identifying_supertype if it defines its own identifier
      def identifying_supertype
	ti = identifying_type_inheritance and ti.supertype
      end

      def common_supertype(other)
        return nil unless other.is_a?(ActiveFacts::Metamodel::EntityType)
        candidates = supertypes_transitive & other.supertypes_transitive
        return candidates[0] if candidates.size <= 1
        candidates[0] # REVISIT: This might not be the closest supertype
      end

      def add_supertype(supertype, is_identifying_supertype, assimilation)
	inheritance_fact = constellation.TypeInheritance(self, supertype, :concept => :new)

	inheritance_fact.assimilation = assimilation

	# Create a reading:
	sub_role = constellation.Role(inheritance_fact, 0, :object_type => self, :concept => :new)
	super_role = constellation.Role(inheritance_fact, 1, :object_type => supertype, :concept => :new)

	rs = constellation.RoleSequence(:new)
	constellation.RoleRef(rs, 0, :role => sub_role)
	constellation.RoleRef(rs, 1, :role => super_role)
	constellation.Reading(inheritance_fact, 0, :role_sequence => rs, :text => "{0} is a kind of {1}", :is_negative => false)

	rs2 = constellation.RoleSequence(:new)
	constellation.RoleRef(rs2, 0, :role => super_role)
	constellation.RoleRef(rs2, 1, :role => sub_role)
	# Decide in which order to include is a/is an. Provide both, but in order.
	n = 'aeioh'.include?(sub_role.object_type.name.downcase[0]) ? 'n' : ''
	constellation.Reading(inheritance_fact, 2, :role_sequence => rs2, :text => "{0} is a#{n} {1}", :is_negative => false)

	if is_identifying_supertype
	  inheritance_fact.provides_identification = true
	end

	# Create uniqueness constraints over the subtyping fact type.
	p1rs = constellation.RoleSequence(:new)
	constellation.RoleRef(p1rs, 0).role = sub_role
	pc1 = constellation.PresenceConstraint(:new, :vocabulary => vocabulary)
	pc1.name = "#{name}MustHaveSupertype#{supertype.name}"
	pc1.role_sequence = p1rs
	pc1.is_mandatory = true   # A subtype instance must have a supertype instance
	pc1.min_frequency = 1
	pc1.max_frequency = 1
	pc1.is_preferred_identifier = false
	trace :constraint, "Made new subtype PC GUID=#{pc1.concept.guid} min=1 max=1 over #{p1rs.describe}"

	p2rs = constellation.RoleSequence(:new)
	constellation.RoleRef(p2rs, 0).role = super_role
	pc2 = constellation.PresenceConstraint(:new, :vocabulary => vocabulary)
	pc2.name = "#{supertype.name}MayBeA#{name}"
	pc2.role_sequence = p2rs
	pc2.is_mandatory = false
	pc2.min_frequency = 0
	pc2.max_frequency = 1
	# The supertype role often identifies the subtype:
	pc2.is_preferred_identifier = inheritance_fact.provides_identification
	trace :supertype, "identification of #{name} via supertype #{supertype.name} was #{inheritance_fact.provides_identification ? '' : 'not '}added"
	trace :constraint, "Made new supertype PC GUID=#{pc2.concept.guid} min=1 max=1 over #{p2rs.describe}"
      end

      # This entity type has just objectified a fact type.
      # Create the necessary ImplicitFactTypes with objectification and mirror roles
      def create_link_fact_types
        fact_type.all_role.map do |role|
          next if role.mirror_role_as_base_role     # Already exists
          link_fact_type = @constellation.LinkFactType(:new, :implying_role => role)
          objectification_role = @constellation.Role(link_fact_type, 0, :object_type => self, :concept => :new)
          mirror_role = @constellation.MirrorRole(link_fact_type, 1, :concept => :new, :object_type => role.object_type, :base_role => role)

          link_fact_type.concept.implication_rule =
          objectification_role.concept.implication_rule =
          mirror_role.concept.implication_rule = 'objectification'
          link_fact_type
        end
      end
    end

    class Reading
      # The frequency_constraints array here, if supplied, may provide for each role either:
      # * a PresenceConstraint to be verbalised against the relevant role, or
      # * a String, used as a definite or indefinite article on the relevant role, or
      # * an array containing two strings (an article and a super-type name)
      # The order in the array is the same as the reading's role-sequence.
      # REVISIT: This should probably be changed to be the fact role sequence.
      #
      # define_role_names here is false (use defined names), true (define names) or nil (neither)
      def expand(frequency_constraints = [], define_role_names = nil, literals = [], &subscript_block)
        expanded = "#{text}"
        role_refs = role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}
        (0...role_refs.size).each{|i|
            role_ref = role_refs[i]
            role = role_ref.role
            l_adj = "#{role_ref.leading_adjective}".sub(/(\b-\b|.\b|.\Z)/, '\1-').sub(/\b--\b/,'-- ').sub(/- /,'-  ')
            l_adj = nil if l_adj == ""
            # Double the space to compensate for space removed below
            # REVISIT: hyphenated trailing adjectives are not correctly represented here
            t_adj = "#{role_ref.trailing_adjective}".sub(/(\b.|\A.)/, '-\1').sub(/ -/,'  -')
            t_adj = nil if t_adj == ""

            expanded.gsub!(/\{#{i}\}/) do
                role_ref = role_refs[i]
                if role_ref.role
                  player = role_ref.role.object_type
                  role_name = role.role_name
                  role_name = nil if role_name == ""
                  if role_name && define_role_names == false
                    l_adj = t_adj = nil   # When using role names, don't add adjectives
                  end

                  freq_con = frequency_constraints[i]
                  freq_con = freq_con.frequency if freq_con && freq_con.is_a?(ActiveFacts::Metamodel::PresenceConstraint)
                  if freq_con.is_a?(Array)
                    freq_con, player_name = *freq_con
                  else
                    player_name = player.name
                  end
                else
                  # We have an unknown role. The reading cannot be correctly expanded
                  player_name = "UNKNOWN"
                  role_name = nil
                  freq_con = nil
                end

                literal = literals[i]
                words = [
                  freq_con ? freq_con : nil,
                  l_adj,
                  define_role_names == false && role_name ? role_name : player_name,
                  t_adj,
                  define_role_names && role_name && player_name != role_name ? "(as #{role_name})" : nil,
                  # Can't have both a literal and a value constraint, but we don't enforce that here:
                  literal ? literal : nil
                ]
                if (subscript_block)
                  words = subscript_block.call(role_ref, *words)
                end
                words.compact*" "
            end
        }
        expanded.gsub!(/ ?- ?/, '-')        # Remove single spaces around adjectives
        #trace "Expanded '#{expanded}' using #{frequency_constraints.inspect}"
        expanded
      end

      def words_and_role_refs
        text.
        scan(/(?: |\{[0-9]+\}|[^{} ]+)/).   # split up the text into words
        reject{|s| s==' '}.                 # Remove white space
        map do |frag|                       # and go through the bits
          if frag =~ /\{([0-9]+)\}/
            role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i}
          else
            frag
          end
        end
      end

      # Return the array of the numbers of the RoleRefs inserted into this reading from the role_sequence
      def role_numbers
        text.scan(/\{(\d)\}/).flatten.map{|m| Integer(m) }
      end

      def expand_with_final_presence_constraint &b
        # Arrange the roles in order they occur in this reading:
        role_refs = role_sequence.all_role_ref_in_order
        role_numbers = text.scan(/\{(\d)\}/).flatten.map{|m| Integer(m) }
        roles = role_numbers.map{|m| role_refs[m].role }
        fact_constraints = fact_type.internal_presence_constraints

        # Find the constraints that constrain frequency over each role we can verbalise:
        frequency_constraints = []
        roles.each do |role|
          frequency_constraints <<
            if (role == roles.last)   # On the last role of the reading, emit any presence constraint
              constraint = fact_constraints.
                detect do |c|  # Find a UC that spans all other Roles
                  c.is_a?(ActiveFacts::Metamodel::PresenceConstraint) &&
                    roles-c.role_sequence.all_role_ref.map(&:role) == [role]
                end
              constraint && constraint.frequency
            else
              nil
            end
        end

        expand(frequency_constraints) { |*a| b && b.call(*a) }
      end
    end

    class ValueConstraint
      def describe
        as_cql
      end

      def as_cql
        "restricted to "+
          ( if regular_expression
              '/' + regular_expression + '/'
            else
              '{' + all_allowed_range_sorted.map{|ar| ar.to_s(false) }*', ' + '}'
            end
          )
      end

      def all_allowed_range_sorted
        all_allowed_range.sort_by{|ar|
            ((min = ar.value_range.minimum_bound) && min.value.literal) ||
              ((max = ar.value_range.maximum_bound) && max.value.literal)
          }
      end

      def to_s
        if all_allowed_range.size > 1
        "[" +
          all_allowed_range_sorted.map { |ar| ar.to_s(true) }*", " +
        "]"
        else
          all_allowed_range.single.to_s
        end
      end
    end

    class AllowedRange
      def to_s(infinity = true)
        min = value_range.minimum_bound
        max = value_range.maximum_bound
        # Open-ended string ranges will fail in Ruby

        if min = value_range.minimum_bound
          min = min.value
          if min.is_literal_string
            min_literal = min.literal.inspect.gsub(/\A"|"\Z/,"'")   # Escape string characters
          else
            min_literal = min.literal
          end
        else
          min_literal = infinity ? "-Infinity" : ""
        end
        if max = value_range.maximum_bound
          max = max.value
          if max.is_literal_string
            max_literal = max.literal.inspect.gsub(/\A"|"\Z/,"'")   # Escape string characters
          else
            max_literal = max.literal
          end
        else
          max_literal = infinity ? "Infinity" : ""
        end

        min_literal +
          (min_literal != (max&&max_literal) ? (".." + max_literal) : "")
      end
    end

    class Value
      def to_s
        if is_literal_string
          "'"+
          literal.
            inspect.            # Use Ruby's inspect to generate necessary escapes
            gsub(/\A"|"\Z/,''). # Remove surrounding quotes
            gsub(/'/, "\\'") +  # Escape any single quotes
          "'"
        else
          literal
        end +
        (unit ? " " + unit.name : "")
      end

      def inspect
        to_s
      end
    end

    class PresenceConstraint
      def frequency
        min = min_frequency
        max = max_frequency
        [
            ((min && min > 0 && min != max) ? "at least #{min == 1 ? "one" : min.to_s}" : nil),
            ((max && min != max) ? "at most #{max == 1 ? "one" : max.to_s}" : nil),
            ((max && min == max) ? "#{max == 1 ? "one" : "exactly "+max.to_s}" : nil)
        ].compact * " and "
      end

      def describe
        min = min_frequency
        max = max_frequency
        'PresenceConstraint over '+role_sequence.describe + " occurs " + frequency + " time#{(min&&min>1)||(max&&max>1) ? 's' : ''}"
      end

      def covers_role role
	role_sequence.all_role_ref.map(&:role).include?(role)
      end
    end

    class SubsetConstraint
      def describe
        'SubsetConstraint(' +
        subset_role_sequence.describe 
        ' < ' +
        superset_role_sequence.describe +
        ')'
      end
    end

    class SetComparisonConstraint
      def describe
        self.class.basename+'(' +
        all_set_comparison_roles.map do |scr|
	  '['+
          scr.role_sequence.all_role_ref.map{|rr|
	    rr.role.fact_type.describe(rr.role)
	  }*',' +
	  ']'
        end*',' +
        ')'
      end
    end

    class RingConstraint
      def describe
        'RingConstraint(' +
        ring_type.to_s+': ' +
        role.describe+', ' +
        other_role.describe+' in ' +
        role.fact_type.default_reading +
        ')'
      end
    end

    class TypeInheritance
      def describe(role = nil)
        "#{subtype.name} is a kind of #{supertype.name}"
      end

      def supertype_role
        (roles = all_role.to_a)[0].object_type == supertype ? roles[0] : roles[1]
      end

      def subtype_role
        (roles = all_role.to_a)[0].object_type == subtype ? roles[0] : roles[1]
      end
    end

    class Step
      def describe
        "Step " +
          "#{is_optional ? 'maybe ' : ''}" +
          (is_unary_step ? '(unary) ' : "from #{input_play.describe} ") +
          "#{is_disallowed ? 'not ' : ''}" +
          "to #{output_plays.map(&:describe)*', '}" +
          (objectification_variable ? ", objectified as #{objectification_variable.describe}" : '') +
          " '#{fact_type.default_reading}'"
      end

      def input_play
        all_play.detect{|p| p.is_input}
      end

      def output_plays
        all_play.reject{|p| p.is_input}
      end

      def is_unary_step
        # Preserve this in case we have to use a real variable for the phantom
        all_play.size == 1
      end

      def is_objectification_step
        !!objectification_variable
      end
    end

    class Variable
      def describe
        object_type.name +
          (subscript ? "(#{subscript})" : '') +
          " Var#{ordinal}" +
          (value ? ' = '+value.to_s : '')
      end

      def all_step
        all_play.map(&:step).uniq
      end
    end

    class Play
      def describe
        "#{role.object_type.name} Var#{variable.ordinal}" +
          (role_ref ? " (projected)" : "")
      end
    end

    class Query
      def describe
        steps_shown = {}
        'Query(' +
          all_variable.sort_by{|var| var.ordinal}.map do |variable|
            variable.describe + ': ' +
            variable.all_step.map do |step|
              next if steps_shown[step]
              steps_shown[step] = true
              step.describe
            end.compact.join(',')
          end.join('; ') +
        ')'
      end

      def show
        steps_shown = {}
        trace :query, "Displaying full contents of Query #{concept.guid}" do
          all_variable.sort_by{|var| var.ordinal}.each do |variable|
            trace :query, "#{variable.describe}" do
              variable.all_step.
                each do |step|
                  next if steps_shown[step]
                  steps_shown[step] = true
                  trace :query, "#{step.describe}"
                end
              variable.all_play.each do |play|
                trace :query, "role of #{play.describe} in '#{play.role.fact_type.default_reading}'"
              end
            end
          end
        end
      end

      def all_step
        all_variable.map{|var| var.all_step.to_a}.flatten.uniq
      end

      # Check all parts of this query for validity
      def validate
        show
        return

        # Check the variables:
        steps = []
        variables = all_variable.sort_by{|var| var.ordinal}
        variables.each_with_index do |variable, i|
          raise "Variable #{i} should have ordinal #{variable.ordinal}" unless variable.ordinal == i
          raise "Variable #{i} has missing object_type" unless variable.object_type
          variable.all_play do |play|
            raise "Variable for #{object_type.name} includes role played by #{play.object_type.name}" unless play.object_type == object_type
          end
          steps += variable.all_step
        end
        steps.uniq!

        # Check the steps:
        steps.each do |step|
          raise "Step has missing fact type" unless step.fact_type
          raise "Step has missing input node" unless step.input_play
          raise "Step has missing output node" unless step.output_play
          if (role = input_play).role.fact_type != fact_type or
            (role = output_play).role.fact_type != fact_type
            raise "Step has role #{role.describe} which doesn't belong to the fact type '#{fact_type.default_reading}' it traverses"
          end
        end

        # REVISIT: Do a connectivity check
      end
    end

    class LinkFactType
      def all_reading
	if super.size == 0
	  # REVISIT: Should we create reading orders independently?
	  # No user-defined readings have been defined, so it's time to stop being lazy:
	  objectification_role, mirror_role = *all_role_in_order
	  rs = constellation.RoleSequence(:new)
	  rr0 = constellation.RoleRef(rs, 0, :role => objectification_role)
	  rr1 = constellation.RoleRef(rs, 1, :role => mirror_role)
	  r0 = constellation.Reading(self, 0, :role_sequence => rs, :text => "{0} involves {1}", :is_negative => false)  # REVISIT: This assumes English!
	  r1 = constellation.Reading(self, 1, :role_sequence => rs, :text => "{1} is involved in {0}", :is_negative => false)
	end
	@all_reading
      end
    end

    class MirrorRole
      def is_mandatory
	base_role.is_mandatory 
      end

      def is_unique
	base_role.is_unique
      end

      def is_functional
	base_role.is_functional
      end

      def uniqueness_constraint
	raise "A MirrorRole should not be asked for its uniqueness constraints"
      end

      %w{all_ring_constraint_as_other_role all_ring_constraint all_role_value role_value_constraint
      }.each do |accessor|
	define_method(accessor.to_sym) do
	  base_role.send(accessor.to_sym)
	end
	define_method("#{accessor}=".to_sym) do |*a|
	  raise "REVISIT: It's a bad idea to try to set #{accessor} for a MirrorRole"
	end
      end
    end

    # Some queries in constraints must be over the proximate roles, some over the counterpart roles.
    # Return the common superclass of the appropriate roles, and the actual roles
    def self.plays_over roles, options = :both   # Or :proximate, :counterpart
      # If we can stay inside this objectified FT, there's no query:
      roles = Array(roles)  # To be safe, in case we get a role collection proxy
      return nil if roles.size == 1 or
        options != :counterpart && roles.map{|role| role.fact_type}.uniq.size == 1
      proximate_sups, counterpart_sups, obj_sups, counterpart_roles, objectification_roles =
        *roles.inject(nil) do |d_c_o, role|
          object_type = role.object_type
          fact_type = role.fact_type

          proximate_role_supertypes = object_type.supertypes_transitive

          # A role in an objectified fact type may indicate either the objectification or the counterpart player.
          # This could be ambiguous. Figure out both and prefer the counterpart over the objectification.
          counterpart_role_supertypes =
            if fact_type.all_role.size > 2
              possible_roles = fact_type.all_role.select{|r| d_c_o && d_c_o[1].include?(r.object_type) }
              if possible_roles.size == 1 # Only one candidate matches the types of the possible variables
                counterpart_role = possible_roles[0]
                d_c_o[1]  # No change
              else
                # puts "#{constraint_type} #{name}: Awkward, try counterpart-role query on a >2ary '#{fact_type.default_reading}'"
                # Try all roles; hopefully we don't have two roles with a matching candidate here:
                # Find which role is compatible with the existing supertypes, if any
                if d_c_o
                  st = nil
                  counterpart_role =
                    fact_type.all_role.detect{|r| ((st = r.object_type.supertypes_transitive) & d_c_o[1]).size > 0}
                  st
                else
                  counterpart_role = nil  # This can't work, we don't have any basis for a decision (must be objectification)
                  []
                end
                #fact_type.all_role.map{|r| r.object_type.supertypes_transitive}.flatten.uniq
              end
            else
              # Get the supertypes of the counterpart role (care with unaries):
              ftr = role.fact_type.all_role.to_a
              (counterpart_role = ftr[0] == role ? ftr[-1] : ftr[0]).object_type.supertypes_transitive
            end

          if fact_type.entity_type
            objectification_role_supertypes =
              fact_type.entity_type.supertypes_transitive+object_type.supertypes_transitive
	    # Find the objectification role here:
            objectification_role = role.link_fact_type.all_role.detect{|r| !r.is_a?(MirrorRole)}
          else
            objectification_role_supertypes = counterpart_role_supertypes
            objectification_role = counterpart_role
          end

          if !d_c_o
            d_c_o = [proximate_role_supertypes, counterpart_role_supertypes, objectification_role_supertypes, [counterpart_role], [objectification_role]]
            #puts "role player supertypes starts #{d_c_o.map{|dco| dco.map(&:name).inspect}*' or '}"
          else
            #puts "continues #{[proximate_role_supertypes, counterpart_role_supertypes, objectification_role_supertypes]map{|dco| dco.map(&:name).inspect}*' or '}"
            d_c_o[0] &= proximate_role_supertypes
            d_c_o[1] &= counterpart_role_supertypes
            d_c_o[2] &= objectification_role_supertypes
            d_c_o[3] << (counterpart_role || objectification_role)
            d_c_o[4] << (objectification_role || counterpart_role)
          end
          d_c_o
        end # inject

      # Discount a subtype step over an object type that's not a player here,
      # if we can use an objectification step to an object type that is:
      if counterpart_sups.size > 0 && obj_sups.size > 0 && counterpart_sups[0] != obj_sups[0]
        trace :query, "ambiguous query, could be over #{counterpart_sups[0].name} or #{obj_sups[0].name}"
        if !roles.detect{|r| r.object_type == counterpart_sups[0]} and roles.detect{|r| r.object_type == obj_sups[0]}
          trace :query, "discounting #{counterpart_sups[0].name} in favour of direct objectification"
          counterpart_sups = []
        end
      end

      # Choose the first entry in the first non-empty supertypes list:
      if options != :counterpart && proximate_sups[0]
        [ proximate_sups[0], roles ]
      elsif !counterpart_sups.empty?
        [ counterpart_sups[0], counterpart_roles ]
      else
        [ obj_sups[0], objectification_roles ]
      end
    end

    class Fact
      def verbalise(context = nil)
        reading = fact_type.preferred_reading
        reading_roles = reading.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}.map{|rr| rr.role }
        role_values_in_reading_order = all_role_value.sort_by{|rv| reading_roles.index(rv.role) }
        instance_verbalisations = role_values_in_reading_order.map do |rv|
          if rv.instance.value
            v = rv.instance.verbalise
          else
            if (c = rv.instance.object_type).is_a?(EntityType)
              if !c.preferred_identifier.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type == fact_type}
                v = rv.instance.verbalise
              end
            end
          end
          next nil unless v
          v.to_s.sub(/(#{rv.instance.object_type.name}|\S*)\s/,'')
        end
        reading.expand([], false, instance_verbalisations)
      end
    end

    class Instance
      def verbalise(context = nil)
        return "#{object_type.name} #{value}" if object_type.is_a?(ValueType)

        return "#{object_type.name} (in which #{fact.verbalise(context)})" if object_type.fact_type

        # It's an entity that's not an objectified fact type

        # If it has a simple identifier, there's no need to fully verbalise the identifying facts.
        # This recursive block returns either the identifying value or nil
        simple_identifier = proc do |instance|
            if instance.object_type.is_a?(ActiveFacts::Metamodel::ValueType)
              instance
            else
              pi = instance.object_type.preferred_identifier
              identifying_role_refs = pi.role_sequence.all_role_ref_in_order
              if identifying_role_refs.size != 1
                nil
              else
                role = identifying_role_refs[0].role
                my_role = (role.fact_type.all_role.to_a-[role])[0]
                identifying_fact = my_role.all_role_value.detect{|rv| rv.instance == self}.fact
                irv = identifying_fact.all_role_value.detect{|rv| rv.role == role}
                identifying_instance = irv.instance
                simple_identifier.call(identifying_instance)
              end
            end
          end

        if (id = simple_identifier.call(self))
          "#{object_type.name} #{id.value}"
        else
          pi = object_type.preferred_identifier
          identifying_role_refs = pi.role_sequence.all_role_ref_in_order
          "#{object_type.name}" +
            " is identified by " +      # REVISIT: Where the single fact type is TypeInheritance, we can shrink this
            identifying_role_refs.map do |rr|
              rr = rr.preferred_reference
              [ (l = rr.leading_adjective) ? l+"-" : nil,
                rr.role.role_name || rr.role.object_type.name,
                (t = rr.trailing_adjective) ? l+"-" : nil
              ].compact*""
            end * " and " +
            " where " +
            identifying_role_refs.map do |rr|  # Go through the identifying roles and emit the facts that define them
              instance_role = object_type.all_role.detect{|r| r.fact_type == rr.role.fact_type}
              identifying_fact = all_role_value.detect{|rv| rv.fact.fact_type == rr.role.fact_type}.fact
              #counterpart_role = (rr.role.fact_type.all_role.to_a-[instance_role])[0]
              #identifying_instance = counterpart_role.all_role_value.detect{|rv| rv.fact == identifying_fact}.instance
              identifying_fact.verbalise(context)
            end*", "
        end

      end
    end

    class ContextNote
      def verbalise(context=nil)
        as_cql
      end

      def as_cql
        ' (' +
        ( if all_context_according_to
            'according to '
            all_context_according_to.map do |act|
              act.agent.agent_name+', '
            end.join('')
          end
        ) +
        context_note_kind.gsub(/_/, ' ') +
        ' ' +
        discussion +
        ( if agreement
            ', as agreed ' +
            (agreement.date ? ' on '+agreement.date.iso8601.inspect+' ' : '') +
            'by '
            agreement.all_context_agreed_by.map do |acab|
              acab.agent.agent_name+', '
            end.join('')
          else
            ''
          end
        ) +
        ')'
      end
    end

    class Composition
      def all_composite_by_name
	all_composite.keys.sort_by do |key|
          @constellation.Composite[key].mapping.name
        end.map do |key|
          composite = @constellation.Composite[key]
	  yield composite if block_given?
	  composite
	end
      end
    end

    class Composite
      def inspect
	"Composite #{mapping.inspect}"
      end

      def show_trace
	trace :composition, inspect do
	  trace :composition?, "Columns" do
	    mapping.show_trace
	  end

	  indices =
	    all_access_path.
	    select{|ap| ap.is_a?(Index)}.
	    sort_by{|ap| [ap.composite_as_primary_index ? 0 : 1] + Array(ap.name)+ap.all_index_field.map(&:inspect) }  # REVISIT: Fix hack for stable ordering
	  unless indices.empty?
	    trace :composition, "Indices" do
	      indices.each do |ap|
		ap.show_trace
	      end
	    end
	  end

	  inbound = all_access_path.
	    select{|ap| ap.is_a?(ForeignKey)}.
	    sort_by{|fk| [fk.source_composite.mapping.name, fk.absorption.inspect]+fk.all_foreign_key_field.map(&:inspect)+fk.all_index_field.map(&:inspect) }
	  unless inbound.empty?
	    trace :composition, "Foreign keys inbound" do
	      inbound.each do |fk|
		fk.show_trace
	      end
	    end
	  end

	  outbound =
	    all_foreign_key_as_source_composite.
	    sort_by{|fk| [fk.source_composite.mapping.name, fk.absorption.inspect]+fk.all_index_field.map(&:inspect)+fk.all_foreign_key_field.map(&:inspect) }
	  unless outbound.empty?
	    trace :composition, "Foreign keys outbound" do
	      outbound.each do |fk|
		fk.show_trace
	      end
	    end
	  end
	end
      end

      # Provide a stable ordering for indices, based on the ordering of columns by rank:
      def all_indices_by_rank
        all_access_path.
        reject{|ap| ap.is_a?(ActiveFacts::Metamodel::ForeignKey)}.
        sort_by{|ap| ap.all_index_field.to_a.flat_map{|ixf| ixf.component.rank_path}.compact }
      end
    end

    class AccessPath
      def show_trace
	trace :composition, inspect do
	  if is_a?(ForeignKey)
	    # First list any fields in a foreign key
	    all_foreign_key_field.sort_by(&:ordinal).each do |fk|
	      raise "Internal error: Foreign key not in foreign table!" if fk.component.root != source_composite
	      trace :composition, fk.inspect
	    end
	  end
	  # Now list the fields in the primary key
	  all_index_field.sort_by(&:ordinal).each do |ak|
	    trace :composition, ak.inspect
	  end
	end
      end

      def position_in_index component
	all_index_field.sort_by(&:ordinal).map(&:component).index(component)
      end
    end

    class Index
      def inspect
	case
	when !is_unique
	  'Non-unique index'
	when composite_as_primary_index
	  'Primary index'
	else
	  'Unique index'
	end +
	(name ? " #{name.inspect}" : '') +
	" to #{composite.mapping.name}" +
	(presence_constraint ? " over #{presence_constraint.describe}" : '')
      end
    end

    class ForeignKey
      def inspect
	"Foreign Key" +
	(name ? " #{name.inspect}" : '') +
	" from #{source_composite.mapping.name} to #{composite.mapping.name}" +
	(absorption ? " over #{absorption.inspect}" : '')
      end
    end

    class IndexField
      def inspect
	"IndexField part #{ordinal} in #{component.root.mapping.name} references #{component.inspect}" +
	(value ? " discriminated by #{value.inspect}" : '')
      end
    end

    class ForeignKeyField
      def inspect
	operation = value ? "filters by value #{value} of" : "is"
	"ForeignKeyField part #{ordinal} in #{component.root.mapping.name} #{operation} #{component.inspect}" +
	(value ? " discriminated by #{value.inspect}" : '')
      end
    end

    class Mapping
      def inspect
	"#{self.class.basename} (#{rank_kind})#{parent ? " in #{parent.name}" :''} of #{name && name != '' ? name : '<anonymous>'}"
      end

      def show_trace
	trace :composition, "#{ordinal ? "#{ordinal}: " : ''}#{inspect}" do
	  yield if block_given?
	  all_member.sort_by{|member| [member.ordinal, member.name]}.each do |member|
	    member.show_trace
	  end
	end
      end

      # Recompute a contiguous member ranking fron zero, based on current membership:
      def re_rank
        all_member.each(&:uncache_rank_key)
        next_rank = 0
        all_member.
	sort_by(&:rank_key).
        each do |member|
          member.ordinal = next_rank
          next_rank += 1
        end
      end

      def root
	composite || parent && parent.root
      end

      def leaves
        re_rank
        all_member.sort_by(&:ordinal).flat_map do |member|
          if member.is_a?(Mapping) && member.all_member.size > 0
            member.leaves
          else
            member
          end
        end
      end
    end

    class Nesting
      def show_trace
	# The index role has a counterpart played by the parent object in the enclosing Absorption
	reading = index_role.fact_type.default_reading
	trace :composition, "#{ordinal}: Nesting under #{index_role.object_type.name}#{key_name ? " (as #{key_name.inspect})" : ''} in #{reading.inspect}}"
      end
    end

    class Absorption
      def inspect_reading
	parent_role.fact_type.reading_preferably_starting_with_role(parent_role).expand.inspect
      end

      def inspect
	"#{super}#{full_absorption ? ' (full)' : ''
	} in #{inspect_reading}#{
	  # If we have a related forward absorption, we're by definition a reverse absorption
	  if forward_absorption
	    ' (reverse)'
	   else
	      # If we have a related reverse absorption, we're by definition a forward absorption
	      reverse_absorption ? ' (forward)' : ''
	  end
	}"
      end

      def show_trace
	super() do
	  if nesting_mode || all_nesting.size > 0
	    trace :composition, "Nested using #{nesting_mode || 'unspecified'} mode" do
	      all_nesting.sort_by(&:ordinal).each(&:show_trace)
	    end
	  end
	end
      end

      def is_type_inheritance
	child_role.fact_type.is_a?(TypeInheritance) && child_role.fact_type
      end

      def is_supertype_absorption
	is_type_inheritance && child_role.fact_type.supertype == object_type
      end

      def is_subtype_absorption
	is_type_inheritance && parent_role.fact_type.supertype == object_type
      end

      def is_preferred_direction
	return child_role.is_mirror_role if child_role.is_mirror_role != parent_role.is_mirror_role

	# Prefer to absorb the one into the many:
	p_un = parent_role.is_unique
	c_un = child_role.is_unique
	return p_un if p_un != c_un

	# Prefer to absorb a subtype into the supertype (opposite if separate or partitioned)
	if (ti = child_role.fact_type).is_a?(TypeInheritance)
	  is_subtype = child_role == ti.subtype_role  # Supertype absorbing subtype
	  subtype = ti.subtype_role.object_type	      # Subtype doesn't want to be absorbed?
	  # REVISIT: We need fewer ways to say this:
	  child_separate = ["separate", "partitioned"].include?(ti.assimilation) ||
	    subtype.is_independent ||
	    subtype.concept.all_concept_annotation.detect{|ca| ca.mapping_annotation == 'separate'}
	  return !is_subtype != !child_separate
	end

	if p_un && c_un
	  # Prefer to absorb a ValueType into an EntityType rather than the other way around:
	  pvt = parent_role.object_type.is_a?(ActiveFacts::Metamodel::ValueType)
	  cvt = child_role.object_type.is_a?(ActiveFacts::Metamodel::ValueType)
	  return cvt if pvt != cvt

	  if !pvt
	    # Force the decision if one EntityType identifies another
	    return true if child_role.base_role.is_identifying  # Parent is identified by child role, correct
	    return false if parent_role.base_role.is_identifying # Child is identified by parent role, incorrect
	  end

	  # Primary absorption absorbs the object playing the mandatory role into the non-mandatory:
	  return child_role.is_mandatory if !parent_role.is_mandatory != !child_role.is_mandatory
	end

	if parent_role.object_type.is_a?(ActiveFacts::Metamodel::EntityType) &&
	     child_role.object_type.is_a?(ActiveFacts::Metamodel::EntityType)
	  # Prefer to absorb an identifying element into the EntityType it identifies
	  return true if parent_role.object_type.preferred_identifier.
	    role_sequence.all_role_ref.map(&:role).detect{|r|
	      r.object_type == child_role.object_type
	    }
	  return false if child_role.object_type.preferred_identifier.
	    role_sequence.all_role_ref.map(&:role).detect{|r|
	      r.object_type == parent_role.object_type
	    }
	end

	# For stability, absorb a later-named role into an earlier-named one:
	return parent_role.name < child_role.name
      end

      def flip!
	raise "REVISIT: Need to flip FullAbsorption on #{inspect}" if full_absorption or reverse_absorption && reverse_absorption.full_absorption or forward_absorption && forward_absorption.full_absorption
	if (other = forward_absorption)
	  # We point at them - make them point at us instead
	  self.forward_absorption = nil
	  self.reverse_absorption = other
	elsif (other = reverse_absorption)
	  # They point at us - make us point at them instead
	  self.reverse_absorption = nil
	  self.forward_absorption = other
	else
	  raise "Absorption cannot be flipped as it has no reverse"
	end
      end

    end

    class FullAbsorption
      def inspect
	"Full #{absorption.inspect}"
      end
    end

    class Indicator
      def inspect
	"#{self.class.basename} #{role.fact_type.default_reading.inspect}"
      end

      def show_trace
	trace :composition, "#{ordinal ? "#{ordinal}: " : ''}#{inspect} #{name ? "(as #{name.inspect})" : ''}"
      end
    end

    class Discriminator
      def inspect
	"#{self.class.basename} between #{all_discriminated_role.map{|dr|dr.fact_type.default_reading.inspect}*', '}"
      end

      def show_trace
	trace :composition, "#{ordinal ? "#{ordinal}: " : ''}#{inspect} #{name ? " (as #{name.inspect})" : ''}"
      end
    end

    class ValueField
      def inspect
	"#{self.class.basename} #{object_type.name.inspect}"
      end

      def show_trace
	trace :composition, "#{ordinal}: #{inspect}#{name ? " (as #{name.inspect})" : ''}"
      end
    end

    class Component
      # The ranking key of a component indicates its importance to its parent:
      # Ranking assigns a total order, but is computed in groups:
      RANK_SURROGATE = 0
      RANK_SUPER = 1		# Supertypes, with the identifying supertype first, others alphabetical
      RANK_IDENT = 2		# Identifying components (absorptions, indicator), in order of the identifier
      RANK_VALUE = 3		# A ValueField
      RANK_INJECTION = 4	# Injections, in alphabetical order
      RANK_DISCRIMINATOR = 5	# Discriminator components, in alphabetical order
      RANK_FOREIGN = 6		# REVISIT: Foreign key components
      RANK_INDICATOR = 7	# Indicators in alphabetical order
      RANK_MANDATORY = 8	# Absorption: unique mandatory
      RANK_NON_MANDATORY = 9	# Absorption: unique optional
      RANK_MULTIPLE = 10	# Absorption: manifold
      RANK_SUBTYPE = 11		# Subtypes in alphabetical order
      RANK_SCOPING = 12		# Scoping in alphabetical order

      def uncache_rank_key
	@rank_key = nil
      end

      def rank_key
	@rank_key ||=
	  case self
	  when SurrogateKey
	    if !parent.parent
	      [RANK_SURROGATE]	# an injected PK
	    else
	      [RANK_MANDATORY, name]	# an FK
	    end

	  when Indicator
	    if (p = parent_entity_type) and (position = p.rank_in_preferred_identifier(role.base_role))
	      [RANK_IDENT, position]     # An identifying unary
	    else
	      [RANK_INDICATOR, name || role.name]	      # A non-identifying unary
	    end

	  when Discriminator
	    [RANK_DISCRIMINATOR, name || child_role.name]

	  when ValueField
	    [RANK_IDENT]

	  when Injection
	    [RANK_INJECTION, name]	      # REVISIT: Injection not fully elaborated. A different sub-key for ranking may be needed

	  when Absorption
	    if is_type_inheritance
	      # We are traversing a type inheritance fact type. Is this object_type the subtype or supertype?
	      if is_supertype_absorption
		# What's the rank of this supertype?
		tis = parent_role.object_type.all_type_inheritance_as_subtype.sort_by{|ti| ti.provides_identification ? '' : ti.supertype.name }
		[RANK_SUPER, child_role.fact_type.provides_identification ? 0 : 1+tis.index(parent_role.fact_type)]
	      else
		# What's the rank of this subtype?
		tis = parent_role.object_type.all_type_inheritance_as_supertype.sort_by{|ti| ti.subtype.name }
		[RANK_SUBTYPE, tis.index(parent_role.fact_type)]
	      end
	    elsif (p = parent_entity_type) and (position = p.rank_in_preferred_identifier(child_role.base_role))
	      [RANK_IDENT, position]
	    else
	      if parent_role.is_unique
		[parent_role.is_mandatory ? RANK_MANDATORY : RANK_NON_MANDATORY, name || child_role.name]
	      else
		[RANK_MULTIPLE, name || child_role.name, parent_role.name]
	      end
	    end

	  when Scoping
	    [RANK_SCOPING, name || object_type.name]

	  else
	    raise "unexpected #{self.class.basename} in Component#rank_key"
	  end
      end

      def primary_index_components
	root and
	ix = root.primary_index and				# Primary index has been decided
	root.primary_index.all_index_field.size > 0 and		# has been populated and
	ix = root.primary_index and
	ixfs = ix.all_index_field.sort_by(&:ordinal) and
	ixfs.map(&:component)
      end

      def parent_entity_type
	parent &&
	  parent.object_type.is_a?(EntityType) &&
	  parent.object_type
      end

      def rank_kind
	return "top" unless parent  # E.g. a Mapping that is a Composite
	case rank_key[0]
	when RANK_SURROGATE;	"surrogate"
	when RANK_SUPER;	"supertype"
	when RANK_IDENT;	"existential"
	when RANK_VALUE;	"self-value"
	when RANK_INJECTION;	"injection"
	when RANK_DISCRIMINATOR;"discriminator"
	when RANK_FOREIGN;	"foreignkey"
	when RANK_INDICATOR;	"indicator"
	when RANK_MANDATORY;	"mandatory"
	when RANK_NON_MANDATORY;"optional"
	when RANK_MULTIPLE;	"multiple"
	when RANK_SUBTYPE;	"subtype"
	when RANK_SCOPING;	"scoping"
	end
      end

      def root
	parent.root
      end

      def depth
	parent ? 1+parent.depth : 0
      end

      def inspect
	"#{self.class.basename}"
      end

      def show_trace
	raise "Implemented in subclasses"
	# trace :composition, "#{ordinal ? "#{ordinal}: " : ''}#{inspect}#{name ? " (as #{name.inspect})" : ''}"
      end

      def leaves
        self
      end

      def path
        (parent ? parent.path+[self] : [self])
      end

      def rank_path
        (parent ? parent.rank_path+[ordinal] : [ordinal])
      end
    end
  end
end
