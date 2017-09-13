require 'activefacts/api'

module ActiveFacts
  module Metamodel
    class Component
      identified_by   :guid
      one_to_one      :guid, mandatory: true              # Component has Guid, see Guid#component
      maybe           :has_absolute_name                  # Has Absolute Name
      has_one         :name                               # Component projects Name, see Name#all_component
      has_one         :ordinal                            # Component has Ordinal rank, see Ordinal#all_component
      has_one         :parent, class: Component, counterpart: :member  # Member belongs to Parent, see Component#all_member
    end

    class Mapping < Component
      has_one         :object_type, mandatory: true       # Mapping represents Object Type, see ObjectType#all_mapping
      has_one         :native_type_name, class: "Name"    # Mapping uses native- type Name, see Name#all_mapping_as_native_type_name
    end

    class AccessPath
      identified_by   :guid
      one_to_one      :guid, mandatory: true              # Access Path has Guid, see Guid#access_path
      has_one         :composite, mandatory: true         # Access Path is to Composite, see Composite#all_access_path
      has_one         :name                               # Access Path is called Name, see Name#all_access_path
    end

    class Guid < ::Guid
      value_type
    end

    class Name < String
      value_type      length: 64
    end

    class Composition
      identified_by   :guid
      one_to_one      :guid, mandatory: true              # Composition has Guid, see Guid#composition
      one_to_one      :name, mandatory: true              # Composition is called Name, see Name#composition
    end

    class Constraint
      identified_by   :concept
      one_to_one      :concept, mandatory: true           # Constraint is an instance of Concept, see Concept#constraint
      has_one         :name                               # Constraint is called Name, see Name#all_constraint
      has_one         :vocabulary                         # Constraint belongs to Vocabulary, see Vocabulary#all_constraint
    end

    class Frequency < UnsignedInteger
      value_type      length: 32
    end

    class RoleSequence
      identified_by   :guid
      one_to_one      :guid, mandatory: true              # Role Sequence has Guid, see Guid#role_sequence
      maybe           :has_unused_dependency_to_force_table_in_norma  # Has Unused Dependency To Force Table In Norma
    end

    class PresenceConstraint < Constraint
      maybe           :is_mandatory                       # Is Mandatory
      maybe           :is_preferred_identifier            # Is Preferred Identifier
      has_one         :role_sequence, mandatory: true     # Presence Constraint covers Role Sequence, see RoleSequence#all_presence_constraint
      has_one         :max_frequency, class: Frequency    # Presence Constraint has max-Frequency, see Frequency#all_presence_constraint_as_max_frequency
      has_one         :min_frequency, class: Frequency    # Presence Constraint has min-Frequency, see Frequency#all_presence_constraint_as_min_frequency
    end

    class Index < AccessPath
      maybe           :is_unique                          # Is Unique
      has_one         :presence_constraint, mandatory: true  # Index derives from Presence Constraint, see PresenceConstraint#all_index
    end

    class Composite
      identified_by   :mapping
      one_to_one      :mapping, mandatory: true           # Composite consists of Mapping, see Mapping#composite
      has_one         :composition, mandatory: true       # Composite belongs to Composition, see Composition#all_composite
      one_to_one      :natural_index, class: Index        # Composite has natural-Index, see Index#composite_as_natural_index
      one_to_one      :primary_index, class: Index        # Composite has primary-Index, see Index#composite_as_primary_index
    end

    class ForeignKey < AccessPath
      has_one         :source_composite, mandatory: true, class: Composite  # Foreign Key traverses from source-Composite, see Composite#all_foreign_key_as_source_composite
    end

    class Pronoun < String
      value_type      length: 20
    end

    class VersionNumber < String
      value_type      length: 32
    end

    class Vocabulary
      identified_by   :name
      one_to_one      :name, mandatory: true              # Vocabulary is called Name, see Name#vocabulary
      maybe           :is_transform                       # Is Transform
      has_one         :version_number                     # Vocabulary has semantic Version Number, see VersionNumber#all_vocabulary
    end

    class ObjectType
      identified_by   :vocabulary, :name
      has_one         :vocabulary, mandatory: true        # Object Type belongs to Vocabulary, see Vocabulary#all_object_type
      has_one         :name, mandatory: true              # Object Type is called Name, see Name#all_object_type
      has_one         :pronoun                            # Object Type uses Pronoun, see Pronoun#all_object_type
    end

    class FullAbsorption
      identified_by   :composition, :object_type
      has_one         :composition, mandatory: true       # Full Absorption involves Composition, see Composition#all_full_absorption
      has_one         :object_type, mandatory: true       # Full Absorption involves Object Type, see ObjectType#all_full_absorption
    end

    class NestingMode < String
      value_type
    end

    class Description < String
      value_type
    end

    class ImplicationRuleName < String
      value_type
    end

    class ImplicationRule
      identified_by   :implication_rule_name
      one_to_one      :implication_rule_name, mandatory: true  # Implication Rule has Implication Rule Name, see ImplicationRuleName#implication_rule
    end

    class Population
      identified_by   :vocabulary, :name
      has_one         :vocabulary                         # Population belongs to Vocabulary, see Vocabulary#all_population
      has_one         :name, mandatory: true              # Population has Name, see Name#all_population
    end

    class Topic
      identified_by   :topic_name
      one_to_one      :topic_name, mandatory: true, class: Name  # Topic has topic-Name, see Name#topic_as_topic_name
    end

    class Concept
      identified_by   :guid
      one_to_one      :guid, mandatory: true              # Concept has Guid, see Guid#concept
      has_one         :implication_rule                   # Concept is implied by Implication Rule, see ImplicationRule#all_concept
      has_one         :informal_description, class: Description  # Concept has informal-Description, see Description#all_concept_as_informal_description
      one_to_one      :object_type                        # Object Type is an instance of Concept, see ObjectType#concept
      one_to_one      :population                         # Population is an instance of Concept, see Population#concept
      one_to_one      :role                               # Role is an instance of Concept, see Role#concept
      has_one         :topic                              # Concept belongs to Topic, see Topic#all_concept
    end

    class Query
      identified_by   :concept
      one_to_one      :concept, mandatory: true           # Query is an instance of Concept, see Concept#query
    end

    class FactType
      identified_by   :concept
      one_to_one      :concept, mandatory: true           # Fact Type is an instance of Concept, see Concept#fact_type
      one_to_one      :query, counterpart: :derived_fact_type  # derived-Fact Type is projected from Query, see Query#derived_fact_type
    end

    class LinkFactType < FactType
    end

    class Ordinal < UnsignedInteger
      value_type      length: 16
    end

    class RegularExpression < String
      value_type
    end

    class DomainObjectType < ObjectType
      maybe           :is_independent                     # Is Independent
    end

    class Length < UnsignedInteger
      value_type      length: 32
    end

    class Scale < UnsignedInteger
      value_type      length: 32
    end

    class TransactionPhase < String
      value_type
    end

    class Denominator < UnsignedInteger
      value_type      length: 32
    end

    class Numerator < Decimal
      value_type
    end

    class Coefficient
      identified_by   :numerator, :denominator, :is_precise
      has_one         :numerator, mandatory: true         # Coefficient has Numerator, see Numerator#all_coefficient
      has_one         :denominator, mandatory: true       # Coefficient has Denominator, see Denominator#all_coefficient
      maybe           :is_precise                         # Is Precise
    end

    class EphemeraURL < String
      value_type
    end

    class Offset < Decimal
      value_type
    end

    class Unit
      identified_by   :concept
      one_to_one      :concept, mandatory: true           # Unit is an instance of Concept, see Concept#unit
      maybe           :is_fundamental                     # Is Fundamental
      one_to_one      :name, mandatory: true              # Unit is called Name, see Name#unit
      has_one         :vocabulary, mandatory: true        # Unit is in Vocabulary, see Vocabulary#all_unit
      has_one         :coefficient                        # Unit has Coefficient, see Coefficient#all_unit
      has_one         :ephemera_url, class: EphemeraURL   # Unit uses coefficient from Ephemera URL, see EphemeraURL#all_unit_as_ephemera_url
      has_one         :offset                             # Unit has Offset, see Offset#all_unit
      one_to_one      :plural_name, class: Name, counterpart: :plural_named_unit  # Plural Named Unit has plural-Name, see Name#plural_named_unit
    end

    class ValueType < DomainObjectType
      has_one         :length                             # Value Type has Length, see Length#all_value_type
      has_one         :scale                              # Value Type has Scale, see Scale#all_value_type
      has_one         :supertype, class: ValueType        # Value Type is subtype of Supertype, see ValueType#all_value_type_as_supertype
      has_one         :transaction_phase                  # Value Type is auto-assigned at Transaction Phase, see TransactionPhase#all_value_type
      has_one         :unit                               # Value Type is of Unit, see Unit#all_value_type
    end

    class ValueConstraint < Constraint
      has_one         :regular_expression                 # Value Constraint requires matching Regular Expression, see RegularExpression#all_value_constraint
      one_to_one      :value_type                         # Value Constraint constrains Value Type, see ValueType#value_constraint
    end

    class AlternativeSet
      identified_by   :guid
      one_to_one      :guid, mandatory: true              # Alternative Set has Guid, see Guid#alternative_set
      maybe           :members_are_exclusive              # Members Are Exclusive
    end

    class Step
      identified_by   :query, :ordinal
      has_one         :query, mandatory: true             # Step is in Query, see Query#all_step
      has_one         :ordinal, mandatory: true           # Step has Ordinal position, see Ordinal#all_step
      maybe           :is_disallowed                      # Is Disallowed
      maybe           :is_optional                        # Is Optional
      has_one         :fact_type, mandatory: true         # Step specifies Fact Type, see FactType#all_step
      has_one         :alternative_set                    # Step falls under Alternative Set, see AlternativeSet#all_step
    end

    class Subscript < UnsignedInteger
      value_type      length: 16
    end

    class Literal < String
      value_type
    end

    class Value
      identified_by   :literal, :is_literal_string, :unit
      has_one         :literal, mandatory: true           # Value is represented by Literal, see Literal#all_value
      maybe           :is_literal_string                  # Is Literal String
      has_one         :unit                               # Value is in Unit, see Unit#all_value
      has_one         :value_type, mandatory: true        # Value is of Value Type, see ValueType#all_value
    end

    class Variable
      identified_by   :query, :ordinal
      has_one         :query, mandatory: true             # Variable is in Query, see Query#all_variable
      has_one         :ordinal, mandatory: true           # Variable has Ordinal position, see Ordinal#all_variable
      has_one         :object_type, mandatory: true       # Variable is for Object Type, see ObjectType#all_variable
      has_one         :role_name, class: Name             # Variable has role-Name, see Name#all_variable_as_role_name
      one_to_one      :step, counterpart: :objectification_variable  # Objectification Variable matches nesting over Step, see Step#objectification_variable
      has_one         :subscript                          # Variable has Subscript, see Subscript#all_variable
      has_one         :value                              # Variable is bound to Value, see Value#all_variable
    end

    class Role
      identified_by   :fact_type, :ordinal
      has_one         :fact_type, mandatory: true         # Role belongs to Fact Type, see FactType#all_role
      has_one         :ordinal, mandatory: true           # Role fills Ordinal, see Ordinal#all_role
      has_one         :object_type, mandatory: true       # Role is played by Object Type, see ObjectType#all_role
      one_to_one      :link_fact_type, counterpart: :implying_role  # implying-Role implies Link Fact Type, see LinkFactType#implying_role
      has_one         :role_name, class: Name             # Role has role-Name, see Name#all_role_as_role_name
      one_to_one      :role_value_constraint, class: ValueConstraint  # Role has role-Value Constraint, see ValueConstraint#role_as_role_value_constraint
      one_to_one      :variable, counterpart: :projection  # Projection is projected from Variable, see Variable#projection
    end

    class Absorption < Mapping
      maybe           :flattens                           # Flattens
      has_one         :child_role, mandatory: true, class: Role  # Absorption traverses to child-Role, see Role#all_absorption_as_child_role
      has_one         :parent_role, mandatory: true, class: Role  # Absorption traverses from parent-Role, see Role#all_absorption_as_parent_role
      one_to_one      :foreign_key                        # Absorption gives rise to Foreign Key, see ForeignKey#absorption
      one_to_one      :full_absorption                    # Absorption creates Full Absorption, see FullAbsorption#absorption
      has_one         :nesting_mode                       # Absorption uses Nesting Mode, see NestingMode#all_absorption
      one_to_one      :reverse_absorption, class: Absorption, counterpart: :forward_absorption  # forward-Absorption is matched by reverse-Absorption, see Absorption#forward_absorption
    end

    class Adjective < String
      value_type      length: 64
    end

    class AgentName < String
      value_type
    end

    class Agent
      identified_by   :agent_name
      one_to_one      :agent_name, mandatory: true        # Agent has Agent Name, see AgentName#agent
    end

    class AggregateCode < String
      value_type      length: 32
    end

    class Aggregate
      identified_by   :aggregate_code
      one_to_one      :aggregate_code, mandatory: true    # Aggregate has Aggregate Code, see AggregateCode#aggregate
    end

    class Aggregation
      identified_by   :aggregate, :aggregated_variable
      has_one         :aggregate, mandatory: true         # Aggregation involves Aggregate, see Aggregate#all_aggregation
      has_one         :aggregated_variable, mandatory: true, class: Variable  # Aggregation involves aggregated-Variable, see Variable#all_aggregation_as_aggregated_variable
      has_one         :variable, mandatory: true          # Aggregation involves Variable, see Variable#all_aggregation
    end

    class ContextNoteKind < String
      value_type
    end

    class ContextNote
      identified_by   :concept
      one_to_one      :concept, mandatory: true           # Context Note is an instance of Concept, see Concept#context_note
      has_one         :context_note_kind, mandatory: true  # Context Note has Context Note Kind, see ContextNoteKind#all_context_note
      has_one         :description, mandatory: true       # Context Note has Description, see Description#all_context_note
      has_one         :relevant_concept, class: Concept   # Context Note applies to relevant-Concept, see Concept#all_context_note_as_relevant_concept
    end

    class Date < ::Date
      value_type
    end

    class Agreement
      identified_by   :context_note
      one_to_one      :context_note, mandatory: true      # Agreement covers Context Note, see ContextNote#agreement
      has_one         :date                               # Agreement was on Date, see Date#all_agreement
    end

    class Bound
      identified_by   :value, :is_inclusive
      has_one         :value, mandatory: true             # Bound has Value, see Value#all_bound
      maybe           :is_inclusive                       # Is Inclusive
    end

    class ValueRange
      identified_by   :minimum_bound, :maximum_bound
      has_one         :minimum_bound, class: Bound        # Value Range has minimum-Bound, see Bound#all_value_range_as_minimum_bound
      has_one         :maximum_bound, class: Bound        # Value Range has maximum-Bound, see Bound#all_value_range_as_maximum_bound
    end

    class AllowedRange
      identified_by   :value_constraint, :value_range
      has_one         :value_constraint, mandatory: true  # Allowed Range involves Value Constraint, see ValueConstraint#all_allowed_range
      has_one         :value_range, mandatory: true       # Allowed Range involves Value Range, see ValueRange#all_allowed_range
    end

    class Annotation < String
      value_type
    end

    class Assimilation < String
      value_type
    end

    class Shape
      identified_by   :guid
      one_to_one      :guid, mandatory: true              # Shape has Guid, see Guid#shape
      has_one         :orm_diagram, mandatory: true, class: "ORMDiagram"  # Shape is in ORM Diagram, see ORMDiagram#all_shape_as_orm_diagram
      has_one         :location                           # Shape is at Location, see Location#all_shape
    end

    class ComponentShape < Shape
      has_one         :component                          # Component Shape is for Component, see Component#all_component_shape
      has_one         :parent_component_shape, class: ComponentShape  # Component Shape is contained in parent-Component Shape, see ComponentShape#all_component_shape_as_parent_component_shape
    end

    class TransformRule
      identified_by   :guid
      one_to_one      :guid, mandatory: true              # Transform Rule has Guid, see Guid#transform_rule
      has_one         :target_object_type, mandatory: true, class: ObjectType  # Transform Rule maps to target-Object Type, see ObjectType#all_transform_rule_as_target_object_type
    end

    class CompoundTransformRule < TransformRule
      has_one         :source_object_type, class: ObjectType  # Compound Transform Rule maps from source-Object Type, see ObjectType#all_compound_transform_rule_as_source_object_type
      has_one         :source_query, class: Query         # Compound Transform Rule maps from source-Query, see Query#all_compound_transform_rule_as_source_query
    end

    class ConceptAnnotation
      identified_by   :concept, :mapping_annotation
      has_one         :concept, mandatory: true           # Concept Annotation involves Concept, see Concept#all_concept_annotation
      has_one         :mapping_annotation, mandatory: true, class: Annotation  # Concept Annotation involves mapping-Annotation, see Annotation#all_concept_annotation_as_mapping_annotation
    end

    class ConstraintShape < Shape
      has_one         :constraint, mandatory: true        # Constraint Shape is for Constraint, see Constraint#all_constraint_shape
    end

    class ContextAccordingTo
      identified_by   :context_note, :agent
      has_one         :context_note, mandatory: true      # Context According To involves Context Note, see ContextNote#all_context_according_to
      has_one         :agent, mandatory: true             # Context According To involves Agent, see Agent#all_context_according_to
      has_one         :date                               # Context According To was lodged on Date, see Date#all_context_according_to
    end

    class ContextAgreedBy
      identified_by   :agreement, :agent
      has_one         :agreement, mandatory: true         # Context Agreed By involves Agreement, see Agreement#all_context_agreed_by
      has_one         :agent, mandatory: true             # Context Agreed By involves Agent, see Agent#all_context_agreed_by
    end

    class Exponent < SignedInteger
      value_type      length: 16
    end

    class Derivation
      identified_by   :derived_unit, :base_unit
      has_one         :derived_unit, mandatory: true, class: Unit  # Derivation involves Derived Unit, see Unit#all_derivation_as_derived_unit
      has_one         :base_unit, mandatory: true, class: Unit  # Derivation involves Base Unit, see Unit#all_derivation_as_base_unit
      has_one         :exponent                           # Derivation has Exponent, see Exponent#all_derivation
    end

    class Diagram
      identified_by   :vocabulary, :name
      has_one         :vocabulary, mandatory: true        # Diagram is for Vocabulary, see Vocabulary#all_diagram
      has_one         :name, mandatory: true              # Diagram is called Name, see Name#all_diagram
    end

    class Discriminator < Component
    end

    class DiscriminatedRole
      identified_by   :discriminator, :role
      has_one         :discriminator, mandatory: true     # Discriminated Role involves Discriminator, see Discriminator#all_discriminated_role
      has_one         :role, mandatory: true              # Discriminated Role involves Role, see Role#all_discriminated_role
      has_one         :value, mandatory: true             # Discriminated Role involves Value, see Value#all_discriminated_role
    end

    class DisplayRoleNamesSetting < String
      value_type
    end

    class EnforcementCode < String
      value_type      length: 16
    end

    class Enforcement
      identified_by   :constraint
      one_to_one      :constraint, mandatory: true        # Enforcement applies to Constraint, see Constraint#enforcement
      has_one         :enforcement_code, mandatory: true  # Enforcement has Enforcement Code, see EnforcementCode#all_enforcement
      has_one         :agent                              # Enforcement notifies Agent, see Agent#all_enforcement
    end

    class EntityType < DomainObjectType
      one_to_one      :fact_type                          # Entity Type objectifies Fact Type, see FactType#entity_type
      has_one         :implicitly_objectified_fact_type, class: FactType  # Entity Type implicitly objectifies implicitly- objectified Fact Type, see FactType#all_entity_type_as_implicitly_objectified_fact_type
    end

    class ExpressionType < String
      value_type
    end

    class LiteralString < String
      value_type
    end

    class OperatorString < String
      value_type
    end

    class Expression
      identified_by   :guid
      one_to_one      :guid, mandatory: true              # Expression has Guid, see Guid#expression
      has_one         :expression_type, mandatory: true   # Expression has Expression Type, see ExpressionType#all_expression
      has_one         :first_op_expression, class: Expression  # Expression has first- op Expression, see Expression#all_expression_as_first_op_expression
      has_one         :literal_string                     # Expression has Literal String, see LiteralString#all_expression
      has_one         :object_type                        # Expression has Object Type, see ObjectType#all_expression
      has_one         :operator_string                    # Expression has Operator String, see OperatorString#all_expression
      has_one         :second_op_expression, class: Expression  # Expression has second- op Expression, see Expression#all_expression_as_second_op_expression
      has_one         :third_op_expression, class: Expression  # Expression has third- op Expression, see Expression#all_expression_as_third_op_expression
    end

    class Instance
      identified_by   :concept
      one_to_one      :concept, mandatory: true           # Instance is an instance of Concept, see Concept#instance
      has_one         :object_type, mandatory: true       # Instance is of Object Type, see ObjectType#all_instance
      has_one         :population, mandatory: true        # Instance belongs to Population, see Population#all_instance
      has_one         :value                              # Instance has Value, see Value#all_instance
    end

    class Fact
      identified_by   :concept
      one_to_one      :concept, mandatory: true           # Fact is an instance of Concept, see Concept#fact
      has_one         :fact_type, mandatory: true         # Fact is of Fact Type, see FactType#all_fact
      has_one         :population, mandatory: true        # Fact belongs to Population, see Population#all_fact
      one_to_one      :instance                           # Fact is objectified as Instance, see Instance#fact
    end

    class ObjectifiedFactTypeNameShape < Shape
    end

    class Text < String
      value_type      length: 256
    end

    class Reading
      identified_by   :fact_type, :ordinal
      has_one         :fact_type, mandatory: true         # Reading is for Fact Type, see FactType#all_reading
      has_one         :ordinal, mandatory: true           # Reading is in Ordinal position, see Ordinal#all_reading
      maybe           :is_negative                        # Is Negative
      has_one         :role_sequence, mandatory: true     # Reading is in Role Sequence, see RoleSequence#all_reading
      has_one         :text, mandatory: true              # Reading has Text, see Text#all_reading
    end

    class ReadingShape < Shape
      has_one         :reading, mandatory: true           # Reading Shape is for Reading, see Reading#all_reading_shape
    end

    class RotationSetting < String
      value_type
    end

    class FactTypeShape < Shape
      has_one         :fact_type, mandatory: true         # Fact Type Shape is for Fact Type, see FactType#all_fact_type_shape
      has_one         :display_role_names_setting         # Fact Type Shape has Display Role Names Setting, see DisplayRoleNamesSetting#all_fact_type_shape
      one_to_one      :objectified_fact_type_name_shape   # Fact Type Shape has Objectified Fact Type Name Shape, see ObjectifiedFactTypeNameShape#fact_type_shape
      one_to_one      :reading_shape                      # Fact Type Shape has Reading Shape, see ReadingShape#fact_type_shape
      has_one         :rotation_setting                   # Fact Type Shape has Rotation Setting, see RotationSetting#all_fact_type_shape
    end

    class ForeignKeyField
      identified_by   :foreign_key, :ordinal
      has_one         :foreign_key, mandatory: true       # Foreign Key Field involves Foreign Key, see ForeignKey#all_foreign_key_field
      has_one         :ordinal, mandatory: true           # Foreign Key Field involves Ordinal, see Ordinal#all_foreign_key_field
      has_one         :component, mandatory: true         # Foreign Key Field involves Component, see Component#all_foreign_key_field
      has_one         :value                              # Foreign Key Field is discriminated by Value, see Value#all_foreign_key_field
    end

    class VersionPattern < String
      value_type      length: 64
    end

    class Import
      identified_by   :topic, :precursor_topic
      has_one         :topic, mandatory: true             # Import involves Topic, see Topic#all_import
      has_one         :precursor_topic, mandatory: true, class: Topic  # Import involves precursor-Topic, see Topic#all_import_as_precursor_topic
      has_one         :file_name, mandatory: true, class: Name  # Import has file-Name, see Name#all_import_as_file_name
      has_one         :import_role, class: Name           # Import has Import Role, see Name#all_import_as_import_role
      has_one         :version_pattern                    # Import has semantic Version Pattern, see VersionPattern#all_import
    end

    class IndexField
      identified_by   :access_path, :ordinal
      has_one         :access_path, mandatory: true       # Index Field involves Access Path, see AccessPath#all_index_field
      has_one         :ordinal, mandatory: true           # Index Field involves Ordinal, see Ordinal#all_index_field
      has_one         :component, mandatory: true         # Index Field involves Component, see Component#all_index_field
      has_one         :value                              # Index Field is discriminated by Value, see Value#all_index_field
    end

    class Indicator < Component
      has_one         :role, mandatory: true              # Indicator indicates Role played, see Role#all_indicator
      has_one         :false_value, class: Value          # Indicator uses false-Value, see Value#all_indicator_as_false_value
      has_one         :true_value, class: Value           # Indicator uses true-Value, see Value#all_indicator_as_true_value
    end

    class Injection < Mapping
    end

    class LeafConstraint
      identified_by   :component, :leaf_constraint
      has_one         :component, mandatory: true         # Leaf Constraint involves Component, see Component#all_leaf_constraint
      has_one         :leaf_constraint, mandatory: true, class: Constraint  # Leaf Constraint involves leaf-Constraint, see Constraint#all_leaf_constraint_as_leaf_constraint
    end

    class LocalConstraint
      identified_by   :composite, :local_constraint
      has_one         :composite, mandatory: true         # Local Constraint involves Composite, see Composite#all_local_constraint
      has_one         :local_constraint, mandatory: true, class: Constraint  # Local Constraint involves local-Constraint, see Constraint#all_local_constraint_as_local_constraint
    end

    class X < SignedInteger
      value_type      length: 32
    end

    class Y < SignedInteger
      value_type      length: 32
    end

    class Location
      identified_by   :x, :y
      has_one         :x, mandatory: true                 # Location is at X, see X#all_location
      has_one         :y, mandatory: true                 # Location is at Y, see Y#all_location
    end

    class MirrorRole < Role
      one_to_one      :base_role, class: Role             # Mirror Role is for Base Role, see Role#mirror_role_as_base_role
    end

    class ModelNoteShape < Shape
      has_one         :context_note, mandatory: true      # Model Note Shape is for Context Note, see ContextNote#all_model_note_shape
    end

    class Nesting
      identified_by   :absorption, :ordinal
      has_one         :absorption, mandatory: true        # Nesting involves Absorption, see Absorption#all_nesting
      has_one         :ordinal, mandatory: true           # Nesting involves Ordinal, see Ordinal#all_nesting
      has_one         :index_role, mandatory: true, class: Role  # Nesting involves index-Role, see Role#all_nesting_as_index_role
      has_one         :key_name, class: Name              # Nesting has key-Name, see Name#all_nesting_as_key_name
    end

    class ORMDiagram < Diagram
    end

    class ObjectTypeShape < Shape
      maybe           :is_expanded                        # Is Expanded
      has_one         :object_type, mandatory: true       # Object Type Shape is for Object Type, see ObjectType#all_object_type_shape
    end

    class RoleRef
      identified_by   :role_sequence, :ordinal
      has_one         :role_sequence, mandatory: true     # Role Ref involves Role Sequence, see RoleSequence#all_role_ref
      has_one         :ordinal, mandatory: true           # Role Ref involves Ordinal, see Ordinal#all_role_ref
      has_one         :role, mandatory: true              # Role Ref involves Role, see Role#all_role_ref
      has_one         :leading_adjective, class: Adjective  # Role Ref has leading-Adjective, see Adjective#all_role_ref_as_leading_adjective
      has_one         :trailing_adjective, class: Adjective  # Role Ref has trailing-Adjective, see Adjective#all_role_ref_as_trailing_adjective
    end

    class Play
      identified_by   :step, :role
      has_one         :step, mandatory: true              # Play involves Step, see Step#all_play
      has_one         :role, mandatory: true              # Play involves Role, see Role#all_play
      maybe           :is_input                           # Is Input
      has_one         :variable, mandatory: true          # Play involves Variable, see Variable#all_play
      one_to_one      :role_ref                           # Play projects Role Ref, see RoleRef#play
    end

    class RingType < String
      value_type
    end

    class RingConstraint < Constraint
      has_one         :ring_type, mandatory: true         # Ring Constraint is of Ring Type, see RingType#all_ring_constraint
      has_one         :other_role, class: Role            # Ring Constraint has other-Role, see Role#all_ring_constraint_as_other_role
      has_one         :role                               # Ring Constraint has Role, see Role#all_ring_constraint
    end

    class RingConstraintShape < ConstraintShape
      has_one         :fact_type_shape, mandatory: true   # Ring Constraint Shape is attached to Fact Type Shape, see FactTypeShape#all_ring_constraint_shape
    end

    class RoleNameShape < Shape
    end

    class ValueConstraintShape < ConstraintShape
      has_one         :object_type_shape                  # Value Constraint Shape is for Object Type Shape, see ObjectTypeShape#all_value_constraint_shape
    end

    class RoleDisplay
      identified_by   :fact_type_shape, :ordinal
      has_one         :fact_type_shape, mandatory: true   # Role Display involves Fact Type Shape, see FactTypeShape#all_role_display
      has_one         :ordinal, mandatory: true           # Role Display involves Ordinal, see Ordinal#all_role_display
      has_one         :role, mandatory: true              # Role Display involves Role, see Role#all_role_display
      one_to_one      :role_name_shape                    # Role Display has Role Name Shape, see RoleNameShape#role_display
      one_to_one      :value_constraint_shape             # Role Display has Value Constraint Shape, see ValueConstraintShape#role_display
    end

    class RoleValue
      identified_by   :fact, :role
      has_one         :fact, mandatory: true              # Role Value fulfils Fact, see Fact#all_role_value
      has_one         :role, mandatory: true              # Role Value is of Role, see Role#all_role_value
      has_one         :instance, mandatory: true          # Role Value is of Instance, see Instance#all_role_value
      has_one         :population, mandatory: true        # Role Value belongs to Population, see Population#all_role_value
    end

    class Scoping < Mapping
    end

    class SetConstraint < Constraint
    end

    class SetComparisonConstraint < SetConstraint
    end

    class SetComparisonRoles
      identified_by   :set_comparison_constraint, :ordinal
      has_one         :set_comparison_constraint, mandatory: true  # Set Comparison Roles involves Set Comparison Constraint, see SetComparisonConstraint#all_set_comparison_roles
      has_one         :ordinal, mandatory: true           # Set Comparison Roles involves Ordinal, see Ordinal#all_set_comparison_roles
      has_one         :role_sequence, mandatory: true     # Set Comparison Roles involves Role Sequence, see RoleSequence#all_set_comparison_roles
    end

    class SetEqualityConstraint < SetComparisonConstraint
    end

    class SetExclusionConstraint < SetComparisonConstraint
      maybe           :is_mandatory                       # Is Mandatory
    end

    class SimpleTransformRule < TransformRule
      has_one         :expression, mandatory: true        # Simple Transform Rule maps from Expression, see Expression#all_simple_transform_rule
    end

    class SpanningConstraint
      identified_by   :composite, :spanning_constraint
      has_one         :composite, mandatory: true         # Spanning Constraint involves Composite, see Composite#all_spanning_constraint
      has_one         :spanning_constraint, mandatory: true, class: Constraint  # Spanning Constraint involves spanning-Constraint, see Constraint#all_spanning_constraint_as_spanning_constraint
    end

    class SubsetConstraint < SetConstraint
      has_one         :subset_role_sequence, mandatory: true, class: RoleSequence  # Subset Constraint covers subset-Role Sequence, see RoleSequence#all_subset_constraint_as_subset_role_sequence
      has_one         :superset_role_sequence, mandatory: true, class: RoleSequence  # Subset Constraint covers superset-Role Sequence, see RoleSequence#all_subset_constraint_as_superset_role_sequence
    end

    class SurrogateKey < Injection
    end

    class TemporalMapping < Mapping
      has_one         :value_type, mandatory: true        # Temporal Mapping records time using Value Type, see ValueType#all_temporal_mapping
    end

    class TransformPart
      identified_by   :compound_transform_rule, :transform_rule
      has_one         :compound_transform_rule, mandatory: true  # Transform Part involves Compound Transform Rule, see CompoundTransformRule#all_transform_part
      has_one         :transform_rule, mandatory: true    # Transform Part involves Transform Rule, see TransformRule#all_transform_part
    end

    class Transformation
      identified_by   :concept
      one_to_one      :concept, mandatory: true           # Transformation is an instance of Concept, see Concept#transformation
      has_one         :compound_transform_rule, mandatory: true  # Transformation implements Compound Transform Rule, see CompoundTransformRule#all_transformation
    end

    class TypeInheritance < FactType
      identified_by   :subtype, :supertype
      has_one         :subtype, mandatory: true, class: EntityType  # Type Inheritance involves Subtype, see EntityType#all_type_inheritance_as_subtype
      has_one         :supertype, mandatory: true, class: EntityType  # Type Inheritance involves Supertype, see EntityType#all_type_inheritance_as_supertype
      maybe           :provides_identification            # Provides Identification
      has_one         :assimilation                       # Type Inheritance uses Assimilation, see Assimilation#all_type_inheritance
    end

    class ValidFrom < Injection
    end

    class ValueField < Injection
    end

    class ValueTypeParameter
      identified_by   :value_type, :name
      has_one         :value_type, mandatory: true        # Value Type Parameter involves Value Type, see ValueType#all_value_type_parameter
      has_one         :name, mandatory: true              # Value Type Parameter involves Name, see Name#all_value_type_parameter
      has_one         :parameter_value_type, mandatory: true, class: ValueType  # Value Type Parameter requires value of parameter-Value Type, see ValueType#all_value_type_parameter_as_parameter_value_type
    end

    class ValueTypeParameterRestriction
      identified_by   :value_type, :value_type_parameter
      has_one         :value_type, mandatory: true        # Value Type Parameter Restriction involves Value Type, see ValueType#all_value_type_parameter_restriction
      has_one         :value_type_parameter, mandatory: true  # Value Type Parameter Restriction involves Value Type Parameter, see ValueTypeParameter#all_value_type_parameter_restriction
      has_one         :value, mandatory: true             # Value Type Parameter Restriction has Value, see Value#all_value_type_parameter_restriction
    end
  end
end
