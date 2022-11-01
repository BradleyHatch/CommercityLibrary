import {autobind} from 'core-decorators';
import pureRender from 'pure-render-decorator';


export default function applyComponentDecorators(component) {
  return pureRender(autobind(component) || component);
}
