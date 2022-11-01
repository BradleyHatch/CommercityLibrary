import  { render } from 'react-dom';
import window from 'window-or-global';


export default function renderToDom(component, containerId) {
  const processingContainer = window.document.getElementById(containerId);

  render(component, processingContainer);
}
