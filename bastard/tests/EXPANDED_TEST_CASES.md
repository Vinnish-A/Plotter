# Expanded Agent Plot Test Cases

These cases test whether an agent can learn from Vault assets as abstract visual grammar, not as hard-coded screenshots. Source labels and biological names are non-semantic. Colors are references for contrast, harmony, lightness balance, and export-size readability only.

Each case must use `data_main.csv` as the only required machine input. `data_optional.csv` may carry annotations, manual positions, labels, or secondary tracks. The expected output is one independent figure unit with no subplot letters.

## Suite A: Template-Based Complex Figures

These cases test whether the agent can select one strong template family and render it faithfully from abstract CSV columns.

### A1. Circular Chord With Outer Tracks

- Template roots: circos chord, multi-annotation chord, communication chord.
- Required `data_main.csv`: `source`, `target`, `weight`, `source_group`, `target_group`.
- Optional `data_optional.csv`: `node`, `group`, `track_1`, `track_2`, `label_priority`, `ring_order`.
- Grammar: circular node sectors, weighted inner chords, one or more outer annotation rings, grouped legend, no Cartesian axes.
- Pass conditions: chords do not obscure node labels; ring gaps are rhythmic; outer tracks align to node sectors; strongest chroma marks the focus or largest flow.
- Fail conditions: radial labels collide, ring tracks drift from sectors, all links are equal width, or the result degenerates into a plain network.

### A2. Circular Dendrogram Heatmap

- Template roots: circular clustered heatmap, ggtree heatmap, radial tree with annotation tracks.
- Required `data_main.csv`: `row_id`, `column_id`, `value`.
- Optional `data_optional.csv`: `row_group`, `column_group`, `tree_parent`, `tree_child`, `track_value`, `label_priority`.
- Grammar: radial tree or dendrogram, circular heatmap body, outer group rings, compact legends outside the circle.
- Pass conditions: tree tips align to heatmap rows; heatmap cells have readable diverging or sequential scale; labels are filtered by priority when dense.
- Fail conditions: tree and heatmap use independent ordering, radial labels overlap heavily, or the heatmap becomes a rectangular fallback.

### A3. Multi-Level Manhattan Plot

- Template roots: multi-track Manhattan, locus zoom, threshold-annotated point plot.
- Required `data_main.csv`: `chromosome`, `position`, `score`, `feature_id`.
- Optional `data_optional.csv`: `feature_id`, `gene_label`, `track_value`, `threshold`, `focus_window`, `annotation_level`.
- Grammar: chromosome-banded x axis, alternating chromosome groups, significance thresholds, focus labels, optional inner or side track.
- Pass conditions: chromosome boundaries are visible; high-priority labels repel cleanly; thresholds are interpretable; point density does not hide peaks.
- Fail conditions: all chromosomes merge into one scatter cloud, labels cover peak points, or thresholds are unlabeled.

### A4. Comparative Genome Structure

- Template roots: geneviewer cluster structure, comparative genome structure, synteny connectors.
- Required `data_main.csv`: `sample`, `gene_id`, `start`, `end`, `strand`, `family`.
- Optional `data_optional.csv`: `sample_a`, `sample_b`, `gene_a`, `gene_b`, `identity`, `block_id`, `label`.
- Grammar: stacked genome tracks, directional gene arrows, family color mapping, cross-sample synteny connectors.
- Pass conditions: arrows preserve strand direction; connectors attach to gene bodies; sample rows are evenly spaced; labels do not cover arrows.
- Fail conditions: genes become undirected rectangles, connector endpoints float, or the figure becomes a generic timeline.

### A5. Forest Table With Encoded Legend

- Template roots: advanced forest plot, Cox forest table, legend-mapped forest plot.
- Required `data_main.csv`: `term`, `estimate`, `lower`, `upper`, `p_value`, `group`.
- Optional `data_optional.csv`: `term`, `table_column`, `table_value`, `symbol_value`, `row_order`, `section`.
- Grammar: left-aligned table text, central confidence interval axis, group sections, optional mapped dot size or fill.
- Pass conditions: table rows align exactly with intervals; intervals are not clipped; p-values and estimates are readable; section separators are subtle.
- Fail conditions: table and plot rows drift, text is too small, or CI bars overlap unrelated rows.

### A6. Multi-Stage Sankey / Alluvial Flow

- Template roots: gradient Sankey, node-fused Sankey, alluvial composition.
- Required `data_main.csv`: `stage`, `node`, `next_stage`, `next_node`, `value`.
- Optional `data_optional.csv`: `node`, `group`, `node_order`, `label_priority`, `flow_color`, `stage_label`.
- Grammar: staged nodes, smooth flow ribbons, conserved widths, grouped colors, compact node labels.
- Pass conditions: widths visually conserve totals; labels sit outside ribbons; crossings are minimized by ordering.
- Fail conditions: ribbons are straight line segments, labels sit inside dense flow regions, or stages lose alignment.

## Suite B: Template Composition

These cases test whether the agent can combine multiple template grammars into one coherent figure unit. Composition is allowed, but the output must not use subplot letters.

### B1. Dendrogram Heatmap With Dot Matrix And Marginal Bars

- Template roots: clustered heatmap, dot heatmap, side summary bars.
- Required `data_main.csv`: `row_id`, `column_id`, `value`, `dot_size`.
- Optional `data_optional.csv`: `row_group`, `column_group`, `side_score`, `bottom_score`, `label_priority`.
- Grammar: main heatmap body, aligned row dendrogram, dot overlay or adjacent dot matrix, side and bottom summaries.
- Pass conditions: row and column identities are owned by outer label rails; duplicate ticks are removed from auxiliary panels; gaps are intentional.
- Fail conditions: annotation tracks own the primary axes, bottom labels sit above bottom tracks, or summaries misalign with cells.

### B2. Volcano With Focus Expansion And Marginal Density

- Template roots: volcano plot, focus expansion, marginal distribution.
- Required `data_main.csv`: `feature_id`, `x`, `y`, `group`, `significance`.
- Optional `data_optional.csv`: `feature_id`, `label`, `focus_group`, `density_bin`, `callout_priority`.
- Grammar: main volcano body, marginal distributions, focus callout or inset, threshold lines.
- Pass conditions: labels are sparse and prioritized; density panels share scales without duplicating semantic axes; focus inset explains selected points.
- Fail conditions: thresholds are decorative only, label collision hides peaks, or marginal panels dominate the body.

### B3. Chord Network With Heat Strip Summary

- Template roots: chord diagram, network ring, annotation heat strip.
- Required `data_main.csv`: `source`, `target`, `weight`, `source_group`, `target_group`.
- Optional `data_optional.csv`: `node`, `metric_a`, `metric_b`, `node_order`, `label_priority`.
- Grammar: circular chord body plus compact outer continuous or categorical strips.
- Pass conditions: strip segments align to node sectors; legends distinguish link weight from strip values; link alpha prevents overplotting.
- Fail conditions: strip order differs from node order or all visual encodings compete at equal intensity.

### B4. Genome Synteny With Expression Tracks

- Template roots: comparative genome structure, heatmap strip, lollipop annotation.
- Required `data_main.csv`: `sample`, `gene_id`, `start`, `end`, `strand`, `family`.
- Optional `data_optional.csv`: `gene_id`, `condition`, `expression`, `variant_count`, `connector_identity`.
- Grammar: gene arrows, synteny ribbons, aligned expression strips, optional variant lollipops.
- Pass conditions: each auxiliary track maps to the same gene coordinate system; gene arrows remain legible.
- Fail conditions: expression strips have independent x scales or lollipop stems hide gene labels.

### B5. Radial Network With Grouped Bubble Legend

- Template roots: ring network, hierarchical bubble map, network module view.
- Required `data_main.csv`: `source`, `target`, `weight`, `node_group`.
- Optional `data_optional.csv`: `node`, `node_size`, `module`, `ring`, `label_priority`.
- Grammar: radial or ring network, module arcs, node size legend, optional inner grouping.
- Pass conditions: node labels are outside high-density rings; edge width and node size have separate legends.
- Fail conditions: network collapses into a hairball or node size becomes unreadable.

### B6. Forest Plot With Distribution Support

- Template roots: forest plot, raincloud or ridge distribution, table alignment.
- Required `data_main.csv`: `term`, `estimate`, `lower`, `upper`, `group`.
- Optional `data_optional.csv`: `term`, `sample_value`, `density_group`, `table_value`, `section`.
- Grammar: CI forest body plus compact distribution summary per section or selected row group.
- Pass conditions: distribution panels support interpretation without breaking row alignment.
- Fail conditions: distribution panels make row heights inconsistent or table text no longer aligns.

## Suite C: Inspired New Complex Figures

These cases test whether the agent can use templates as visual genes and generate a new complex figure when no exact template exists.

### C1. Focused Chord-To-Detail Expansion

- Inspiration roots: chord diagram, global-to-local focus expansion, heatmap annotation.
- Required `data_main.csv`: `source`, `target`, `weight`, `focus_flag`, `detail_x`, `detail_y`.
- Optional `data_optional.csv`: `entity`, `detail_metric`, `label`, `annotation_group`, `priority`.
- New grammar: global circular flow plus reserved detail sector or side detail panel tied to a focus entity by connectors.
- Pass conditions: the focus entity is explained, not merely highlighted; connectors use empty space; global flow remains readable.
- Fail conditions: detail panel is generic or the focus connector crosses dense chords.

### C2. Manifold Trajectory With Embedded State Tiles

- Inspiration roots: 3D manifold projection, trajectory signal plot, annotated heatmap.
- Required `data_main.csv`: `sample_id`, `x`, `y`, `z`, `trajectory`, `state`, `value`.
- Optional `data_optional.csv`: `state`, `tile_metric`, `time_bin`, `label_priority`.
- New grammar: 3D or projected manifold body with an aligned state-tile strip and trajectory signal support.
- Pass conditions: projection and support tracks share trajectory order; state tiles are secondary but readable.
- Fail conditions: projection becomes decorative while support tracks carry the actual figure.

### C3. Correlation Constellation With Local Matrix

- Inspiration roots: correlation heatmap, network module view, local focus expansion.
- Required `data_main.csv`: `entity_a`, `entity_b`, `correlation`, `group`.
- Optional `data_optional.csv`: `entity`, `focus_flag`, `module`, `local_value`, `label_priority`.
- New grammar: global correlation network arranged by modules, with a local matrix or tile strip for the focus module.
- Pass conditions: correlation sign and strength are distinguishable; local matrix uses the same entity ordering as the focus module.
- Fail conditions: network and local matrix disagree on ordering or color direction.

### C4. Temporal Flow Matrix

- Inspiration roots: Sankey, heatmap, alluvial area.
- Required `data_main.csv`: `time`, `source_state`, `target_state`, `value`.
- Optional `data_optional.csv`: `state`, `state_metric`, `time_metric`, `label_priority`.
- New grammar: staged flow ribbons over a compact time-by-state matrix.
- Pass conditions: flow widths and matrix values are visually distinct encodings; time alignment is exact.
- Fail conditions: matrix and flow use conflicting time order or duplicate labels clutter the figure.

### C5. Circular Genome Interaction Atlas

- Inspiration roots: comparative genome structure, circular chord, outer annotation rings.
- Required `data_main.csv`: `segment`, `start`, `end`, `feature_id`, `feature_group`.
- Optional `data_optional.csv`: `source_feature`, `target_feature`, `interaction_weight`, `track_value`, `label_priority`.
- New grammar: circular genome sectors with gene arrows or blocks, interaction chords, and continuous outer rings.
- Pass conditions: genomic coordinate order is preserved around the circle; interactions do not hide outer tracks.
- Fail conditions: sector order is arbitrary or outer tracks become detached decoration.

### C6. Adaptive Uncertainty Atlas

- Inspiration roots: forest plot, heatmap, focus expansion.
- Required `data_main.csv`: `entity`, `condition`, `estimate`, `lower`, `upper`, `value`.
- Optional `data_optional.csv`: `entity`, `group`, `focus_flag`, `rank`, `annotation`.
- New grammar: heatmap-like condition matrix where selected cells expand into local uncertainty intervals.
- Pass conditions: uncertainty is visible without hiding cell values; expanded intervals are anchored to their source cell.
- Fail conditions: uncertainty is encoded only by text or expanded intervals break matrix alignment.

## Acceptance Gate

Every expanded test case should define:

- `mode`: `template`, `composition`, or `inspired`.
- `source_templates`: Vault asset IDs or families used as visual roots.
- `required_columns`: all required `data_main.csv` columns.
- `optional_columns`: allowed `data_optional.csv` columns.
- `visual_grammar`: marks, layout, encodings, annotation policy, and axis ownership.
- `quality_checks`: no meaningful overlap, consistent text categories, controlled element sizes, curated colors, PDF and PNG size parity, and no subplot letters.
- `failure_signatures`: the specific ways a superficially valid figure can still fail.
