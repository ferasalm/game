class_name DialogueDef
extends Def
## A conversation: an ordered list of lines (speaker, expression, text key). Read-only; stepping is DialogueRun.

var lines: Array[DialogueLine] = []


func read(r: DefReader) -> void:
	id = r.id()
	for line_reader: DefReader in r.objects("lines"):
		var line := DialogueLine.new()
		line.read(line_reader)
		lines.append(line)


func references() -> Array[Array]:
	var out: Array[Array] = []
	for line: DialogueLine in lines:
		out.append(["speaker", line.speaker])
		for choice: DialogueChoice in line.choices:
			if not choice.next.is_empty() and choice.next != &"end":
				out.append(["dialogue", choice.next])
	return out
