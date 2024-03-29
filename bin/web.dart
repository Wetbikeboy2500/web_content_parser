import 'dart:html';
import 'dart:js';

import 'package:web_content_parser/src/wql/wql.dart';

void main() async {
  context['runWQL'] = runWQL;

  //create a modaL
  final modal = Element.div();
  modal.style.display = 'none';
  //create a button
  final button = ButtonElement();
  button.text = 'Click Me';
  button.onClick.listen((event) {
    modal.style.display = 'block';
  });

  //create a span element
  final span = SpanElement();
  span.text = 'x';
  span.style.color = 'red';
  span.style.float = 'right';
  span.style.cursor = 'pointer';
  span.onClick.listen((event) {
    modal.style.display = 'none';
  });

  //create a div element
  final div = DivElement();
  div.style.backgroundColor = 'white';
  div.style.padding = '20px';
  div.style.border = '1px solid #888';
  div.style.width = '100%';
  //height
  div.style.height = '100%';


  //text input
  final input = TextAreaElement();
  input.style.height = '100px';
  input.style.width = '100%';


  //create p element
  final p = ParagraphElement();

  //button to run wql
  final button1 = ButtonElement();
  button1.text = 'Run WQL';
  button1.onClick.listen((event) {
    runWQL(input.value ?? '').then((value) {
      if (value.pass) {
        print(value.data);
      }
    });
  });

  //create a button element
  final button2 = ButtonElement();
  button2.text = 'Close';
  button2.onClick.listen((event) {
    modal.style.display = 'none';
  });

  //add elements to div
  div.append(span);
  div.append(input);
  div.append(button1);
  div.append(p);
  div.append(button2);

  //add div to modal
  modal.append(div);

  document.body!.append(button);
  document.body!.append(modal);
}