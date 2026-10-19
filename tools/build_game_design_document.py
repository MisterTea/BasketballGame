from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_ALIGN_VERTICAL, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "Rim_Rumble_Game_Design_Document_Template.docx"

NAVY = "17365D"
BLUE = "DCE6F1"
PALE_BLUE = "F3F7FB"
PALE_GRAY = "F5F5F5"
MID_GRAY = "666666"
LIGHT_GRAY = "D9D9D9"
WHITE = "FFFFFF"
BLACK = "000000"


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_border(cell, color=LIGHT_GRAY, size="6"):
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = tc_pr.first_child_found_in("w:tcBorders")
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = f"w:{edge}"
        el = borders.find(qn(tag))
        if el is None:
            el = OxmlElement(tag)
            borders.append(el)
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), size)
        el.set(qn("w:color"), color)


def set_cell_margins(cell, top=70, start=100, bottom=70, end=100):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for m, v in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{m}"))
        if node is None:
            node = OxmlElement(f"w:{m}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(v))
        node.set(qn("w:type"), "dxa")


def set_repeat_table_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def set_row_cant_split(row):
    tr_pr = row._tr.get_or_add_trPr()
    cant_split = OxmlElement("w:cantSplit")
    cant_split.set(qn("w:val"), "true")
    tr_pr.append(cant_split)


def remove_paragraph_borders(paragraph):
    p_pr = paragraph._p.get_or_add_pPr()
    borders = p_pr.find(qn("w:pBdr"))
    if borders is not None:
        p_pr.remove(borders)


def set_cell_width(cell, inches):
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_w = tc_pr.find(qn("w:tcW"))
    if tc_w is None:
        tc_w = OxmlElement("w:tcW")
        tc_pr.append(tc_w)
    tc_w.set(qn("w:w"), str(int(inches * 1440)))
    tc_w.set(qn("w:type"), "dxa")


def set_run_font(run, name="Aptos", size=None, bold=None, italic=None, color=BLACK):
    run.font.name = name
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), name)
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), name)
    if size is not None:
        run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold
    if italic is not None:
        run.italic = italic
    run.font.color.rgb = RGBColor.from_string(color)


def add_page_number(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = paragraph.add_run()
    fld_char_1 = OxmlElement("w:fldChar")
    fld_char_1.set(qn("w:fldCharType"), "begin")
    instr_text = OxmlElement("w:instrText")
    instr_text.set(qn("xml:space"), "preserve")
    instr_text.text = " PAGE "
    fld_char_2 = OxmlElement("w:fldChar")
    fld_char_2.set(qn("w:fldCharType"), "end")
    run._r.append(fld_char_1)
    run._r.append(instr_text)
    run._r.append(fld_char_2)
    set_run_font(run, size=9, color=MID_GRAY)


def configure_styles(doc):
    normal = doc.styles["Normal"]
    normal.font.name = "Aptos"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Aptos")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Aptos")
    normal.font.size = Pt(10.25)
    normal.font.color.rgb = RGBColor(0, 0, 0)
    normal.paragraph_format.space_after = Pt(5)
    normal.paragraph_format.line_spacing = 1.04

    title = doc.styles["Title"]
    title.font.name = "Aptos Display"
    title._element.rPr.rFonts.set(qn("w:ascii"), "Aptos Display")
    title._element.rPr.rFonts.set(qn("w:hAnsi"), "Aptos Display")
    title.font.size = Pt(34)
    title.font.bold = True
    title.font.color.rgb = RGBColor(0, 0, 0)
    title.paragraph_format.space_after = Pt(12)
    title_p_pr = title._element.get_or_add_pPr()
    title_border = title_p_pr.find(qn("w:pBdr"))
    if title_border is not None:
        title_p_pr.remove(title_border)

    for name, size, before, after in (
        ("Heading 1", 19, 10, 7),
        ("Heading 2", 14.5, 8, 4),
        ("Heading 3", 11.5, 6, 3),
    ):
        style = doc.styles[name]
        style.font.name = "Aptos Display" if name != "Heading 3" else "Aptos"
        style._element.rPr.rFonts.set(qn("w:ascii"), style.font.name)
        style._element.rPr.rFonts.set(qn("w:hAnsi"), style.font.name)
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor(0, 0, 0)
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True
        if name == "Heading 1":
            style.paragraph_format.page_break_before = True

    subtitle = doc.styles["Subtitle"]
    subtitle.font.name = "Aptos"
    subtitle._element.rPr.rFonts.set(qn("w:ascii"), "Aptos")
    subtitle._element.rPr.rFonts.set(qn("w:hAnsi"), "Aptos")
    subtitle.font.size = Pt(15)
    subtitle.font.color.rgb = RGBColor(0, 0, 0)
    subtitle.paragraph_format.space_after = Pt(18)


def add_intro(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(8)
    r = p.add_run(text)
    set_run_font(r, size=11, color="303030")
    return p


def add_guidance(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    set_run_font(r, size=9.5, italic=True, color=MID_GRAY)
    return p


def add_bullets(doc, items, level=0):
    for item in items:
        p = doc.add_paragraph(style="List Bullet" if level == 0 else "List Bullet 2")
        p.paragraph_format.space_after = Pt(3)
        p.paragraph_format.left_indent = Inches(0.22 + level * 0.2)
        p.paragraph_format.first_line_indent = Inches(-0.14)
        r = p.add_run(item)
        set_run_font(r, size=10.5)


def add_numbered(doc, items):
    for item in items:
        p = doc.add_paragraph(style="List Number")
        p.paragraph_format.space_after = Pt(4)
        r = p.add_run(item)
        set_run_font(r, size=10.5)


def add_table(doc, headers, rows, widths=None, header_fill=NAVY, font_size=9.5):
    table = doc.add_table(rows=1, cols=len(headers))
    table.autofit = False
    table.alignment = WD_ALIGN_PARAGRAPH.CENTER
    table.rows[0]._tr.get_or_add_trPr()
    set_repeat_table_header(table.rows[0])
    set_row_cant_split(table.rows[0])
    for i, header in enumerate(headers):
        cell = table.rows[0].cells[i]
        set_cell_shading(cell, header_fill)
        set_cell_border(cell)
        set_cell_margins(cell, 85, 105, 85, 105)
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        if widths:
            set_cell_width(cell, widths[i])
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_after = Pt(0)
        r = p.add_run(header)
        set_run_font(r, size=font_size, bold=True, color=WHITE if header_fill == NAVY else BLACK)
    for ridx, row_data in enumerate(rows):
        row = table.add_row()
        set_row_cant_split(row)
        for i, value in enumerate(row_data):
            cell = row.cells[i]
            set_cell_shading(cell, PALE_BLUE if ridx % 2 else WHITE)
            set_cell_border(cell)
            set_cell_margins(cell)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            if widths:
                set_cell_width(cell, widths[i])
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if len(str(value)) < 24 and i > 0 else WD_ALIGN_PARAGRAPH.LEFT
            r = p.add_run(str(value))
            set_run_font(r, size=font_size, color=BLACK if value else MID_GRAY)
    return table


def add_prompt_table(doc, prompts, label="Current answer", evidence=True):
    headers = ["Design question", label]
    widths = [2.35, 4.15]
    rows = []
    if evidence:
        headers.append("Evidence or owner")
        widths = [2.15, 3.05, 1.3]
    for prompt in prompts:
        if evidence:
            rows.append([prompt, "Write the current decision here", "Name or source"])
        else:
            rows.append([prompt, "Write the current decision here"])
    return add_table(doc, headers, rows, widths=widths, font_size=9)


def add_section_break(doc, title, purpose):
    doc.add_heading(title, level=1)
    add_intro(doc, purpose)


def add_decision_record(doc):
    doc.add_heading("Decision record", level=2)
    add_guidance(doc, "Record material choices as they are made. A decision is complete only when the rationale, owner, and consequence are visible.")
    add_table(
        doc,
        ["Date", "Decision", "Rationale", "Owner", "Revisit trigger"],
        [
            ["YYYY MM DD", "Decision made", "Why this option won", "Name", "New evidence or milestone"],
            ["YYYY MM DD", "Decision made", "Why this option won", "Name", "New evidence or milestone"],
        ],
        widths=[0.8, 1.55, 2.15, 0.8, 1.2],
        font_size=8.5,
    )


def build():
    doc = Document()
    configure_styles(doc)
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.7)
    section.bottom_margin = Inches(0.65)
    section.left_margin = Inches(0.85)
    section.right_margin = Inches(0.85)
    section.header_distance = Inches(0.3)
    section.footer_distance = Inches(0.3)

    # Cover
    doc.add_paragraph().paragraph_format.space_after = Pt(50)
    p = doc.add_paragraph(style="Title")
    p.add_run("Rim Rumble Game Design Document Template")
    remove_paragraph_borders(p)
    p = doc.add_paragraph(style="Subtitle")
    p.add_run("A working brief for creative direction production planning and investment decisions")
    add_intro(
        doc,
        "This document turns a game idea into a fundable production plan. It should make the player experience concrete, define what the team will build, show how progress will be proven, and expose the choices that affect cost, schedule, and commercial risk.",
    )
    add_table(
        doc,
        ["Document field", "Working value"],
        [
            ["Project", "Rim Rumble"],
            ["Genre", "Arcade basketball"],
            ["Document owner", "Name and role"],
            ["Version", "0.1"],
            ["Decision stage", "Concept  Prototype  Vertical slice  Production  Launch"],
            ["Last updated", "YYYY MM DD"],
            ["Next review", "Date and decision to be made"],
        ],
        widths=[1.85, 4.65],
        header_fill=NAVY,
        font_size=9.5,
    )
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(18)
    r = p.add_run("Prepared for")
    set_run_font(r, size=9, bold=True, color=MID_GRAY)
    p.add_run("  Financier and project sponsors")

    # Use guide and contents
    add_section_break(
        doc,
        "How to use this document",
        "Treat this as the project agreement, not a one-time pitch. Write the shortest answer that lets a reader make a decision. Mark assumptions honestly, attach evidence when it exists, and move detail to an appendix when it obscures the core experience.",
    )
    doc.add_heading("Authoring rules", level=2)
    add_numbered(
        doc,
        [
            "Complete the Executive brief first. If that page is unclear, the rest of the design is not ready to expand.",
            "State what the player does and feels before describing features, technology, or lore.",
            "Separate committed scope from experiments and future ideas. Every committed feature must appear in the schedule and budget.",
            "Replace opinion with evidence where practical. Use prototypes, playtests, comparable products, cost estimates, or technical tests.",
            "Record decisions and the conditions that would cause the team to revisit them.",
        ],
    )
    doc.add_heading("Status language", level=2)
    add_table(
        doc,
        ["Status", "Meaning"],
        [
            ["Proposed", "A candidate direction that has not been approved"],
            ["Testing", "An assumption under active prototype or research"],
            ["Committed", "Included in approved scope budget and schedule"],
            ["Deferred", "Valuable but excluded from the current release"],
            ["Rejected", "Considered and intentionally not pursued"],
        ],
        widths=[1.25, 5.25],
        header_fill="44546A",
    )
    doc.add_heading("Document map", level=2)
    add_table(
        doc,
        ["Part", "What it proves"],
        [
            ["1 Executive brief", "Why this game should exist and what decision is needed"],
            ["2 Creative direction", "What experience the team is protecting"],
            ["3 Player and market", "Who will care and how the game can reach them"],
            ["4 Game design", "What the player does and how the systems create depth"],
            ["5 Content and presentation", "What must be authored and how the game communicates"],
            ["6 Technology and production", "How the team will build and prove it"],
            ["7 Investment and launch", "What funding buys and how success will be measured"],
            ["8 Governance and appendices", "How decisions risks and changes stay controlled"],
        ],
        widths=[2.1, 4.4],
    )

    # Executive brief
    add_section_break(
        doc,
        "1 Executive brief",
        "This section should let a financier understand the opportunity, the proposed product, the size of the commitment, and the next proof point in five minutes.",
    )
    doc.add_heading("Decision requested", level=2)
    add_prompt_table(
        doc,
        [
            "What approval or funding decision is requested now",
            "How much capital or team capacity is requested",
            "What milestone will that commitment reach",
            "What evidence will determine whether funding continues",
        ],
    )
    doc.add_heading("Game in one sentence", level=2)
    add_guidance(doc, "Name the player fantasy, the action, the distinctive twist, and the intended audience. Avoid a list of features.")
    add_table(doc, ["Working statement"], [["Players ______ by ______ in a ______ game built for ______"]], widths=[6.5], header_fill="44546A")
    doc.add_heading("Investment case", level=2)
    add_prompt_table(
        doc,
        [
            "What audience need or market opening makes this timely",
            "What proof already reduces creative or technical risk",
            "What advantage can this team sustain",
            "What outcome would make the investment worthwhile",
        ],
    )
    doc.add_heading("Scope at a glance", level=2)
    add_table(
        doc,
        ["Dimension", "Launch target", "Explicit boundary"],
        [
            ["Platforms", "Target platforms", "Platforms not supported at launch"],
            ["Modes", "Launch modes", "Modes deferred or excluded"],
            ["Players", "Local and online player count", "Unsupported configurations"],
            ["Content", "Teams courts characters and events", "Post launch possibilities"],
            ["Business model", "Price and revenue model", "Practices the game will not use"],
            ["Schedule", "Target window and duration", "Conditions that can move the date"],
        ],
        widths=[1.15, 2.7, 2.65],
        font_size=9,
    )
    doc.add_heading("Measures of success", level=2)
    add_table(
        doc,
        ["Measure", "Target", "When measured", "Why it matters"],
        [
            ["Player response", "Target metric", "Prototype or launch", "Behavior this validates"],
            ["Commercial result", "Target metric", "Window", "Investment outcome"],
            ["Production result", "Target metric", "Milestone", "Delivery confidence"],
            ["Quality result", "Target metric", "Milestone", "Player experience"],
        ],
        widths=[1.35, 1.35, 1.4, 2.4],
        font_size=8.8,
    )
    doc.add_heading("Critical assumptions", level=2)
    add_guidance(doc, "List only assumptions that could change the funding decision, scope, schedule, or commercial case.")
    add_table(
        doc,
        ["Assumption", "Why it matters", "How it will be tested", "Decision date"],
        [
            ["Player demand assumption", "Commercial or creative effect", "Research or playtest", "Date"],
            ["Scope assumption", "Cost or schedule effect", "Estimate or prototype", "Date"],
            ["Technical assumption", "Feasibility or quality effect", "Technical test", "Date"],
            ["Business assumption", "Revenue or operating effect", "Market or financial test", "Date"],
        ],
        widths=[1.55, 1.75, 1.85, 1.35],
        font_size=8.3,
    )

    # Creative direction
    add_section_break(
        doc,
        "2 Creative direction",
        "Define the experience strongly enough that designers, artists, engineers, and investors can judge whether a feature belongs in the game.",
    )
    doc.add_heading("Player fantasy", level=2)
    add_prompt_table(
        doc,
        [
            "Who does the player imagine being",
            "What can the player do that feels unusually satisfying",
            "What emotions should a ten minute session create",
            "What story will players tell afterward",
        ],
        evidence=False,
    )
    doc.add_heading("Design pillars", level=2)
    add_guidance(doc, "Use three to five pillars. Each pillar needs a behavioral test so the team can reject attractive ideas that pull the game off course.")
    add_table(
        doc,
        ["Pillar", "Player meaning", "Design test", "What this excludes"],
        [
            ["Pillar name", "What the player should experience", "Question used in reviews", "Tempting but conflicting choice"],
            ["Pillar name", "What the player should experience", "Question used in reviews", "Tempting but conflicting choice"],
            ["Pillar name", "What the player should experience", "Question used in reviews", "Tempting but conflicting choice"],
        ],
        widths=[1.15, 2.0, 1.75, 1.6],
        font_size=8.6,
    )
    doc.add_heading("Experience arc", level=2)
    add_table(
        doc,
        ["Moment", "Player state", "Desired emotion", "Design responsibility"],
        [
            ["First minute", "What the player understands and attempts", "Feeling", "System or presentation cue"],
            ["First match", "What changes by the end", "Feeling", "System or presentation cue"],
            ["First hour", "What the player learns or earns", "Feeling", "System or presentation cue"],
            ["Long term", "Why the player returns", "Feeling", "System or social driver"],
        ],
        widths=[1.1, 2.1, 1.35, 1.95],
        font_size=8.8,
    )
    doc.add_heading("Tone and world", level=2)
    add_prompt_table(
        doc,
        [
            "What visual and emotional tone defines the game",
            "What rules govern exaggeration humor and spectacle",
            "What references clarify the goal without replacing an original identity",
            "What themes or content boundaries must the team respect",
        ],
        evidence=False,
    )

    # Player and market
    add_section_break(
        doc,
        "3 Player and market",
        "Connect the creative promise to a reachable audience. Claims in this section should eventually be supported by research, playtest behavior, storefront data, or comparable product analysis.",
    )
    doc.add_heading("Primary player", level=2)
    add_prompt_table(
        doc,
        [
            "Who is the primary player in behavior rather than demographics",
            "What games or activities already compete for this player's time",
            "What frustration or unmet desire creates an opening",
            "What would stop this player from trying or returning",
        ],
    )
    doc.add_heading("Audience segments", level=2)
    add_table(
        doc,
        ["Segment", "Need", "Acquisition path", "Retention reason", "Priority"],
        [
            ["Primary", "Player need", "How they discover it", "Why they return", "1"],
            ["Secondary", "Player need", "How they discover it", "Why they return", "2"],
            ["Expansion", "Player need", "How they discover it", "Why they return", "Later"],
        ],
        widths=[1.0, 1.55, 1.55, 1.55, 0.85],
        font_size=8.5,
    )
    doc.add_heading("Comparable products", level=2)
    add_guidance(doc, "Choose products that clarify player expectations, pricing, discoverability, or production scale. Do not call every similar game a direct competitor.")
    add_table(
        doc,
        ["Product", "Relevant lesson", "Our difference", "Evidence to verify"],
        [
            ["Comparable title", "What its players value", "A concrete difference", "Source or test"],
            ["Comparable title", "What its players value", "A concrete difference", "Source or test"],
            ["Comparable title", "What its players value", "A concrete difference", "Source or test"],
        ],
        widths=[1.35, 1.9, 1.8, 1.45],
        font_size=8.5,
    )
    doc.add_heading("Position and promise", level=2)
    add_prompt_table(
        doc,
        [
            "What promise should the store page make",
            "What image or gameplay moment proves that promise quickly",
            "What category and search language will players use",
            "Why will players choose this over the nearest alternatives",
        ],
    )

    # Gameplay
    add_section_break(
        doc,
        "4 Core gameplay",
        "Describe what the player repeatedly does, how decisions create mastery, and how the game produces readable consequences. This is the center of the design document.",
    )
    doc.add_heading("Core loop", level=2)
    add_table(
        doc,
        ["Step", "Player action", "Immediate feedback", "Resource or state change", "Next decision"],
        [
            ["1", "Observe or prepare", "What the game communicates", "What changes", "Choice created"],
            ["2", "Commit to an action", "Response", "What changes", "Choice created"],
            ["3", "Resolve risk or contest", "Response", "What changes", "Choice created"],
            ["4", "Recover or capitalize", "Response", "What changes", "Loop restarts or escalates"],
        ],
        widths=[0.45, 1.45, 1.55, 1.55, 1.5],
        font_size=8.3,
    )
    doc.add_heading("Match flow", level=2)
    add_table(
        doc,
        ["Phase", "Entry condition", "Player decisions", "Exit condition", "Target duration"],
        [
            ["Setup", "How play begins", "Meaningful choices", "Trigger", "Time"],
            ["Opening", "State", "Meaningful choices", "Trigger", "Time"],
            ["Midgame", "State", "Meaningful choices", "Trigger", "Time"],
            ["Climax", "State", "Meaningful choices", "Trigger", "Time"],
            ["Results", "State", "Interpretation and next choice", "Return path", "Time"],
        ],
        widths=[0.85, 1.25, 1.8, 1.25, 1.35],
        font_size=8.3,
    )
    doc.add_heading("Controls and action vocabulary", level=2)
    add_table(
        doc,
        ["Input", "Context", "Action", "Skill expression", "Failure feedback"],
        [
            ["Input", "Offense defense menu or universal", "Result", "Timing positioning or prediction", "Readable response"],
            ["Input", "Context", "Result", "Skill expression", "Readable response"],
            ["Input", "Context", "Result", "Skill expression", "Readable response"],
            ["Input", "Context", "Result", "Skill expression", "Readable response"],
        ],
        widths=[0.85, 1.3, 1.35, 1.65, 1.35],
        font_size=8.3,
    )
    doc.add_heading("Moment to moment decisions", level=2)
    add_prompt_table(
        doc,
        [
            "What information does the player read before acting",
            "What tradeoffs prevent one dominant action",
            "How does the game reward timing positioning prediction and teamwork",
            "How does a losing player recover without erasing earned advantage",
        ],
    )

    doc.add_heading("Rules and edge cases", level=2)
    add_guidance(doc, "Put only player-relevant rules here. Keep implementation logic and exhaustive test cases in technical documentation.")
    add_table(
        doc,
        ["Situation", "Rule", "Reason", "Player feedback", "Test case"],
        [
            ["Situation", "Authoritative rule", "Design reason", "Visual audio or text cue", "Test identifier"],
            ["Situation", "Authoritative rule", "Design reason", "Visual audio or text cue", "Test identifier"],
            ["Situation", "Authoritative rule", "Design reason", "Visual audio or text cue", "Test identifier"],
        ],
        widths=[1.1, 1.55, 1.35, 1.45, 1.05],
        font_size=8.1,
    )
    doc.add_heading("Rule authority", level=2)
    add_prompt_table(
        doc,
        [
            "Which rules are universal and which vary by mode",
            "When two rules conflict which one takes priority",
            "How are ties simultaneous events and interrupted actions resolved",
            "Which exceptions are intentional enough to teach explicitly",
        ],
    )
    doc.add_heading("Open rulings log", level=2)
    add_table(
        doc,
        ["Question", "Temporary ruling", "Evidence needed", "Owner", "Decision date"],
        [
            ["Unresolved player-facing case", "Current playtest ruling", "Test or design review", "Name", "Date"],
            ["Unresolved player-facing case", "Current playtest ruling", "Test or design review", "Name", "Date"],
            ["Unresolved player-facing case", "Current playtest ruling", "Test or design review", "Name", "Date"],
        ],
        widths=[1.55, 1.45, 1.45, 0.75, 0.85],
        font_size=8.0,
    )

    # Systems
    add_section_break(
        doc,
        "5 Systems balance and progression",
        "Show how individual mechanics interact, how the game teaches mastery, and how tuning will be measured. Avoid false precision until playtest data exists.",
    )
    doc.add_heading("System inventory", level=2)
    add_table(
        doc,
        ["System", "Player purpose", "Inputs", "Outputs", "Dependencies", "Status"],
        [
            ["Movement", "Why the player uses it", "Inputs or state", "Outcome", "Related systems", "Proposed"],
            ["Scoring", "Why the player uses it", "Inputs or state", "Outcome", "Related systems", "Proposed"],
            ["Defense", "Why the player uses it", "Inputs or state", "Outcome", "Related systems", "Proposed"],
            ["Momentum or power", "Why the player uses it", "Inputs or state", "Outcome", "Related systems", "Proposed"],
            ["Progression", "Why the player uses it", "Inputs or state", "Outcome", "Related systems", "Proposed"],
        ],
        widths=[1.05, 1.35, 1.05, 1.15, 1.25, 0.65],
        font_size=7.8,
    )
    doc.add_heading("Economy and progression", level=2)
    add_prompt_table(
        doc,
        [
            "What changes between sessions and what resets",
            "What rewards express mastery without creating unfair power",
            "What currencies resources or unlocks exist and why",
            "What prevents grind confusion exploitation or pay pressure",
        ],
    )
    doc.add_heading("Difficulty and fairness", level=2)
    add_table(
        doc,
        ["Audience", "Challenge target", "Assistance", "Failure response", "Validation"],
        [
            ["New player", "Expected task", "Teaching or aid", "How failure stays useful", "Test and threshold"],
            ["Returning player", "Expected task", "Aid or none", "Recovery path", "Test and threshold"],
            ["Expert player", "Expected task", "Competitive safeguards", "Counterplay", "Test and threshold"],
        ],
        widths=[1.15, 1.55, 1.3, 1.45, 1.05],
        font_size=8.3,
    )
    doc.add_heading("Tuning plan", level=2)
    add_table(
        doc,
        ["Question", "Metric", "Test setup", "Decision threshold", "Owner"],
        [
            ["What needs tuning", "Observable measure", "Players build and sample", "Change or accept rule", "Name"],
            ["What needs tuning", "Observable measure", "Players build and sample", "Change or accept rule", "Name"],
            ["What needs tuning", "Observable measure", "Players build and sample", "Change or accept rule", "Name"],
        ],
        widths=[1.45, 1.25, 1.55, 1.55, 0.7],
        font_size=8.2,
    )

    # Modes and content
    add_section_break(
        doc,
        "6 Modes and content",
        "Define the playable package and the amount of authored content required. Every row should connect to a production estimate and a player need.",
    )
    doc.add_heading("Mode matrix", level=2)
    add_table(
        doc,
        ["Mode", "Players", "Session", "Unique rules", "Content need", "Launch status"],
        [
            ["Primary mode", "Count and configuration", "Target length", "Difference", "Assets and systems", "Committed"],
            ["Secondary mode", "Count and configuration", "Target length", "Difference", "Assets and systems", "Proposed"],
            ["Online mode", "Count and configuration", "Target length", "Difference", "Services and moderation", "Proposed"],
            ["Training", "Count", "Target length", "Teaching structure", "Lessons and UI", "Proposed"],
        ],
        widths=[1.05, 1.15, 0.9, 1.3, 1.45, 0.65],
        font_size=7.8,
    )
    doc.add_heading("Content budget", level=2)
    add_table(
        doc,
        ["Content type", "Launch quantity", "Variation strategy", "Cost driver", "Minimum viable set"],
        [
            ["Playable characters or teams", "Count", "How variety is created", "Art design animation audio", "Count"],
            ["Venues or levels", "Count", "How variety is created", "Art lighting rules audio", "Count"],
            ["Animations", "Count or families", "Reuse and blending", "Capture generation cleanup", "Minimum"],
            ["Audio", "Count or minutes", "Variation and reuse", "Composition voice implementation", "Minimum"],
            ["Cosmetics or rewards", "Count", "Modular strategy", "Art UI approvals", "Minimum"],
        ],
        widths=[1.35, 1.05, 1.55, 1.55, 1.0],
        font_size=8,
    )
    doc.add_heading("Content cadence", level=2)
    add_prompt_table(
        doc,
        [
            "How long should the launch package remain fresh",
            "What content is systemic and what must be hand authored",
            "What content can be cut without damaging the core promise",
            "What post launch cadence is affordable and credible",
        ],
    )

    # Presentation and UX
    add_section_break(
        doc,
        "7 Presentation user experience and accessibility",
        "Explain how players understand the action, navigate the product, and experience its identity. Presentation choices should support gameplay readability before spectacle.",
    )
    doc.add_heading("Visual direction", level=2)
    add_prompt_table(
        doc,
        [
            "What visual principles define characters environments and effects",
            "How does the camera preserve awareness and excitement",
            "Which information must remain readable at gameplay speed",
            "What art risks require an early style test",
        ],
    )
    doc.add_heading("Audio direction", level=2)
    add_prompt_table(
        doc,
        [
            "What must audio communicate during play",
            "What musical identity and adaptive behavior support the tone",
            "What voice commentary crowd music and licensing commitments are required",
        ],
    )
    doc.add_heading("Experience flow", level=2)
    add_table(
        doc,
        ["Screen or state", "Player goal", "Required choices", "Exit path", "Failure prevention"],
        [
            ["First launch", "Goal", "Choices", "Next state", "How confusion is prevented"],
            ["Main menu", "Goal", "Choices", "Next state", "How confusion is prevented"],
            ["Mode setup", "Goal", "Choices", "Next state", "How errors are corrected"],
            ["Gameplay", "Goal", "Choices", "Next state", "Pause reconnect or quit"],
            ["Results", "Goal", "Choices", "Next state", "How progress is explained"],
        ],
        widths=[1.15, 1.35, 1.45, 1.15, 1.4],
        font_size=8.1,
    )
    doc.add_heading("Accessibility commitments", level=2)
    add_table(
        doc,
        ["Need", "Launch support", "Design dependency", "Test method", "Owner"],
        [
            ["Motor", "Features and remapping", "Input and timing", "Players and checklist", "Name"],
            ["Vision", "Contrast scale and noncolor cues", "UI art effects", "Audit and players", "Name"],
            ["Hearing", "Captions and visual equivalents", "Audio UI", "Audit and players", "Name"],
            ["Cognition", "Clarity pacing and assistance", "Tutorial UI rules", "Players and checklist", "Name"],
        ],
        widths=[0.8, 1.8, 1.35, 1.55, 1.0],
        font_size=8.2,
    )

    # Tech and online
    add_section_break(
        doc,
        "8 Technology and online design",
        "Describe technical choices in terms of player impact, schedule, cost, and operating risk. Link detailed architecture and test procedures rather than reproducing them here.",
    )
    doc.add_heading("Technical baseline", level=2)
    add_table(
        doc,
        ["Area", "Current choice", "Reason", "Constraint", "Proof required"],
        [
            ["Engine", "Godot version and renderer", "Why it fits", "Platform or staffing limit", "Build or benchmark"],
            ["Platforms", "Targets", "Why", "Certification hardware scope", "Export and device test"],
            ["Networking", "Model and services", "Player requirement", "Latency security cost", "Impairment test"],
            ["Persistence", "Local or service backed", "Player requirement", "Privacy recovery cost", "Failure test"],
            ["Content pipeline", "Tools and formats", "Team requirement", "Throughput and quality", "Representative asset"],
        ],
        widths=[1.0, 1.55, 1.4, 1.45, 1.1],
        font_size=7.9,
    )
    doc.add_heading("Performance budgets", level=2)
    add_table(
        doc,
        ["Budget", "Target", "Minimum hardware", "Measurement scene", "Current result"],
        [
            ["Frame rate", "Target", "Device", "Worst representative scene", "Result and date"],
            ["Frame time", "CPU and GPU", "Device", "Scene", "Result and date"],
            ["Memory", "Target", "Device", "Scene", "Result and date"],
            ["Download and storage", "Target", "Platform", "Build", "Result and date"],
            ["Network", "Latency loss bandwidth", "Connection", "Scenario", "Result and date"],
        ],
        widths=[1.15, 1.25, 1.4, 1.55, 1.15],
        font_size=8,
    )
    doc.add_heading("Online experience", level=2)
    add_prompt_table(
        doc,
        [
            "How players find invite and join one another",
            "Who owns authoritative game state and why",
            "What happens during latency packet loss disconnect and host departure",
            "What identity safety moderation privacy and anticheat duties exist",
        ],
    )
    doc.add_heading("Technical unknowns", level=2)
    add_table(
        doc,
        ["Unknown", "Player or business impact", "Test", "Deadline", "Owner"],
        [
            ["Unknown", "Impact if unresolved", "Cheapest decisive test", "Date", "Name"],
            ["Unknown", "Impact if unresolved", "Cheapest decisive test", "Date", "Name"],
            ["Unknown", "Impact if unresolved", "Cheapest decisive test", "Date", "Name"],
        ],
        widths=[1.4, 1.75, 1.65, 0.9, 0.8],
        font_size=8.2,
    )

    # Production
    add_section_break(
        doc,
        "9 Production plan",
        "Turn the design into a sequence of evidence-producing milestones. A milestone is complete when the agreed player experience works in a representative build, not when a list of tasks is exhausted.",
    )
    doc.add_heading("Milestone plan", level=2)
    add_table(
        doc,
        ["Milestone", "Decision unlocked", "Playable evidence", "Exit criteria", "Target date"],
        [
            ["Concept", "Approve prototype", "Pitch and risk map", "Core hypothesis is testable", "Date"],
            ["Prototype", "Approve vertical slice", "Core loop in gray box", "Fun and feasibility thresholds", "Date"],
            ["Vertical slice", "Approve production", "Representative quality segment", "Cost quality and pipeline proven", "Date"],
            ["Alpha", "Approve content completion", "All major systems and content paths", "Feature complete criteria", "Date"],
            ["Beta", "Approve release candidate", "Content complete stabilized build", "Quality performance and compliance", "Date"],
            ["Launch", "Ship and operate", "Release build and operations", "Platform and business readiness", "Date"],
        ],
        widths=[0.9, 1.45, 1.65, 1.8, 0.7],
        font_size=7.8,
    )
    doc.add_heading("Vertical slice definition", level=2)
    add_prompt_table(
        doc,
        [
            "Which complete player journey will the slice contain",
            "Which art audio UI and performance quality bars must be representative",
            "Which pipelines and production rates must be proven",
            "Which commercial assumptions will the slice test",
        ],
    )
    doc.add_heading("Team plan", level=2)
    add_table(
        doc,
        ["Discipline", "Core responsibility", "Staffing by phase", "External support", "Risk"],
        [
            ["Design", "Responsibilities", "Prototype to launch", "Contractor or partner", "Gap or dependency"],
            ["Engineering", "Responsibilities", "Prototype to launch", "Contractor or partner", "Gap or dependency"],
            ["Art and animation", "Responsibilities", "Prototype to launch", "Contractor or partner", "Gap or dependency"],
            ["Audio", "Responsibilities", "Prototype to launch", "Contractor or partner", "Gap or dependency"],
            ["Production and QA", "Responsibilities", "Prototype to launch", "Contractor or partner", "Gap or dependency"],
            ["Business and community", "Responsibilities", "Prototype to launch", "Partner", "Gap or dependency"],
        ],
        widths=[1.05, 1.5, 1.4, 1.35, 1.2],
        font_size=7.7,
    )
    doc.add_heading("Definition of done", level=2)
    add_bullets(
        doc,
        [
            "The feature works in the integrated target build and supports the intended player behavior.",
            "User experience, accessibility, audio, analytics, localization, and error handling are included where relevant.",
            "Automated and manual checks pass, known limitations are recorded, and performance remains within budget.",
            "The product owner accepts the result against written criteria and any follow-up work has an owner and date.",
        ],
    )

    # Investment and budget
    add_section_break(
        doc,
        "10 Budget and financing",
        "Show what the requested investment buys, when cash is needed, which assumptions drive the estimate, and how the financier can stop or expand responsibly.",
    )
    doc.add_heading("Funding tranches", level=2)
    add_table(
        doc,
        ["Tranche", "Amount", "Use of funds", "Duration", "Release condition", "Stop condition"],
        [
            ["Prototype", "Currency", "Team tools tests", "Months", "Approval and start", "Failed core hypothesis"],
            ["Vertical slice", "Currency", "Representative production", "Months", "Prototype evidence", "Quality or cost miss"],
            ["Production", "Currency", "Full team and content", "Months", "Slice approval", "Forecast breach"],
            ["Launch reserve", "Currency", "Certification marketing operations", "Months", "Beta evidence", "Readiness miss"],
        ],
        widths=[0.85, 0.75, 1.45, 0.7, 1.45, 1.3],
        font_size=7.6,
    )
    doc.add_heading("Cost model", level=2)
    add_table(
        doc,
        ["Category", "Assumption", "Low", "Base", "High", "Confidence"],
        [
            ["Internal team", "People months and loaded cost", "Amount", "Amount", "Amount", "Level"],
            ["External production", "Scope and rates", "Amount", "Amount", "Amount", "Level"],
            ["Technology and services", "Licenses hosting tools", "Amount", "Amount", "Amount", "Level"],
            ["Testing and compliance", "Devices labs ratings localization", "Amount", "Amount", "Amount", "Level"],
            ["Marketing and distribution", "Campaign platform and creative", "Amount", "Amount", "Amount", "Level"],
            ["Contingency", "Percent and covered risks", "Amount", "Amount", "Amount", "Level"],
        ],
        widths=[1.3, 1.75, 0.75, 0.75, 0.75, 1.2],
        font_size=7.6,
    )
    doc.add_heading("Commercial model", level=2)
    add_prompt_table(
        doc,
        [
            "What will the player pay and what will remain included",
            "What unit sales active users retention or conversion assumptions drive the model",
            "What platform fees taxes refunds support and operating costs apply",
            "What downside base and upside outcomes matter to the investment decision",
        ],
    )
    doc.add_heading("Financial controls", level=2)
    add_bullets(
        doc,
        [
            "Compare actual spend, committed spend, remaining forecast, and contingency at each milestone review.",
            "Require written approval when scope or forecast crosses the agreed change threshold.",
            "Keep launch marketing and post-launch operations visible rather than hiding them inside development cost.",
            "Update revenue assumptions only when new evidence changes price, audience, conversion, retention, or platform reach.",
        ],
    )

    # Launch
    add_section_break(
        doc,
        "11 Launch and live operations",
        "Define how the game reaches players, how launch readiness will be judged, and what obligations remain after release.",
    )
    doc.add_heading("Launch strategy", level=2)
    add_prompt_table(
        doc,
        [
            "Which territories platforms and languages launch first",
            "What release window and external events affect timing",
            "What demo festival creator press or community beats create awareness",
            "What storefront assets and gameplay proof will convert interest",
        ],
    )
    doc.add_heading("Readiness checklist", level=2)
    add_table(
        doc,
        ["Area", "Ready when", "Evidence", "Owner", "Status"],
        [
            ["Product", "Quality and content criteria", "Build report", "Name", "Open"],
            ["Platform", "Certification and store criteria", "Approval", "Name", "Open"],
            ["Operations", "Monitoring support and incident plan", "Rehearsal", "Name", "Open"],
            ["Commercial", "Price assets campaign and partners", "Approved plan", "Name", "Open"],
            ["Legal", "Rights privacy ratings and terms", "Signoff", "Name", "Open"],
            ["Community", "Channels moderation and response plan", "Staffed plan", "Name", "Open"],
        ],
        widths=[1.05, 1.75, 1.4, 1.0, 1.3],
        font_size=8,
    )
    doc.add_heading("Post launch plan", level=2)
    add_table(
        doc,
        ["Horizon", "Player promise", "Planned work", "Decision data", "Budget owner"],
        [
            ["Day 0 to 7", "Stability and response", "Monitoring fixes support", "Crashes reviews concurrency", "Name"],
            ["Day 8 to 30", "Quality and first improvements", "Patches balance communication", "Retention sessions sentiment", "Name"],
            ["Month 2 to 3", "Reason to return", "Content events or features", "Cohorts revenue demand", "Name"],
            ["Beyond", "Sustainable commitment", "Roadmap based on evidence", "Profitability and capacity", "Name"],
        ],
        widths=[1.05, 1.55, 1.55, 1.55, 0.8],
        font_size=8,
    )

    # Risk and governance
    add_section_break(
        doc,
        "12 Risk decisions and change control",
        "Make uncertainty manageable. Track the few risks that could materially change the player promise, budget, schedule, legal position, or ability to operate the game.",
    )
    doc.add_heading("Risk register", level=2)
    add_table(
        doc,
        ["Risk", "Chance", "Effect", "Warning", "Response", "Owner"],
        [
            ["Risk statement", "Low medium high", "Cost schedule quality or legal", "Observable warning", "Action before it occurs", "Name"],
            ["Risk statement", "Low medium high", "Impact", "Observable warning", "Mitigation", "Name"],
            ["Risk statement", "Low medium high", "Impact", "Observable warning", "Mitigation", "Name"],
            ["Risk statement", "Low medium high", "Impact", "Observable warning", "Mitigation", "Name"],
            ["Risk statement", "Low medium high", "Impact", "Observable warning", "Mitigation", "Name"],
        ],
        widths=[1.4, 0.8, 1.3, 1.2, 1.2, 0.6],
        font_size=7.5,
    )
    add_decision_record(doc)
    doc.add_heading("Change control", level=2)
    add_table(
        doc,
        ["Change", "Reason", "Player effect", "Cost and schedule effect", "Decision"],
        [
            ["Requested change", "Evidence or need", "Benefit and harm", "Estimate and milestone impact", "Approve defer reject"],
            ["Requested change", "Evidence or need", "Benefit and harm", "Estimate and milestone impact", "Approve defer reject"],
        ],
        widths=[1.25, 1.35, 1.35, 1.55, 1.0],
        font_size=8,
    )
    doc.add_heading("Review cadence", level=2)
    add_table(
        doc,
        ["Review", "Cadence", "Participants", "Required evidence", "Decision output"],
        [
            ["Design review", "Weekly or milestone", "Creative and product", "Playable build and questions", "Design decisions"],
            ["Production review", "Weekly", "Leads and producer", "Schedule risks and dependencies", "Recovery actions"],
            ["Financial review", "Monthly", "Sponsor producer finance", "Actuals forecast contingency", "Funding control"],
            ["Milestone review", "Gate date", "Sponsor and leads", "Build results budget risk", "Continue change or stop"],
        ],
        widths=[1.1, 1.0, 1.4, 1.65, 1.35],
        font_size=8.1,
    )

    # Appendix
    add_section_break(
        doc,
        "Appendix working briefs",
        "Use these compact briefs for reviews and handoffs. Keep the main document authoritative and link detailed research, specifications, test plans, and production trackers from the source register.",
    )
    doc.add_heading("One page pitch brief", level=2)
    add_prompt_table(
        doc,
        [
            "Title genre platform and business model",
            "One sentence game promise",
            "Three design pillars",
            "Primary audience and evidence",
            "Signature gameplay moment",
            "Scope schedule team and funding request",
            "Next milestone and pass fail evidence",
        ],
        label="Pitch answer",
        evidence=False,
    )
    doc.add_heading("Playtest brief", level=2)
    add_table(
        doc,
        ["Field", "Plan"],
        [
            ["Question", "The single decision this test should inform"],
            ["Participants", "Target players sample size and recruitment"],
            ["Build and scenario", "Version mode duration and setup"],
            ["Measures", "Behavioral measures survey items and observation"],
            ["Threshold", "Result that supports changes or rejects the hypothesis"],
            ["Bias controls", "What the moderator will not explain or lead"],
            ["Decision date", "When the team will review the evidence"],
        ],
        widths=[1.55, 4.95],
    )
    doc.add_heading("Milestone review brief", level=2)
    add_table(
        doc,
        ["Question", "Answer"],
        [
            ["What did this milestone need to prove", "Write the approved exit criteria"],
            ["What does the build prove now", "Summarize observed evidence"],
            ["What remains uncertain", "List material unknowns only"],
            ["What changed in scope budget or schedule", "State variance and cause"],
            ["What decision is requested", "Continue change pause or stop"],
            ["What happens next", "Name owner date and next evidence"],
        ],
        widths=[2.25, 4.25],
        header_fill="44546A",
    )
    source_heading = doc.add_heading("Source register", level=2)
    source_heading.paragraph_format.page_break_before = True
    add_table(
        doc,
        ["Source", "Purpose", "Owner", "Updated", "Location"],
        [
            ["Player research", "Audience and need", "Name", "Date", "Link or path"],
            ["Comparable analysis", "Market and product expectations", "Name", "Date", "Link or path"],
            ["Technical plan", "Architecture performance and online", "Name", "Date", "Link or path"],
            ["Production plan", "Schedule staffing dependencies", "Name", "Date", "Link or path"],
            ["Financial model", "Cost revenue and cash timing", "Name", "Date", "Link or path"],
            ["Test reports", "Quality and milestone evidence", "Name", "Date", "Link or path"],
        ],
        widths=[1.25, 1.7, 0.85, 0.85, 1.85],
        font_size=8,
    )
    doc.add_heading("Glossary", level=2)
    add_table(
        doc,
        ["Term", "Project definition"],
        [
            ["Term", "Definition used consistently by the team"],
            ["Term", "Definition used consistently by the team"],
            ["Term", "Definition used consistently by the team"],
            ["Term", "Definition used consistently by the team"],
        ],
        widths=[1.75, 4.75],
    )

    # Header and footer, after content so all sections inherit the same setup.
    for sec in doc.sections:
        hp = sec.header.paragraphs[0]
        hp.text = "RIM RUMBLE  GAME DESIGN DOCUMENT"
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hp.paragraph_format.space_after = Pt(0)
        if hp.runs:
            set_run_font(hp.runs[0], size=8, bold=True, color=BLACK)
        fp = sec.footer.paragraphs[0]
        add_page_number(fp)

    # Keep cover clean.
    doc.sections[0].different_first_page_header_footer = True

    # Core properties.
    doc.core_properties.title = "Rim Rumble Game Design Document Template"
    doc.core_properties.subject = "Game design production and investment planning template"
    doc.core_properties.author = "Rim Rumble project team"
    doc.core_properties.keywords = "game design document, GDD, production, budget, financing, Rim Rumble"

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    build()
