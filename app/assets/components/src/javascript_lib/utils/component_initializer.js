import genericComponents from 'javascript_lib/components/generic_components';

import renderToDom from 'javascript_lib/utils/render_to_dom';


export default function componentInitializer(appComponents) {
  return (componentType, componentId, params=null) => {
    const componentToRender = getComponent(appComponents, componentType, params);

    if(componentToRender) {
      renderToDom(componentToRender, componentId);
    }
  };
}

function getComponent(appComponents, componentType, params) {
  let component = null;

  component = genericComponents(componentType, params);

  return component ? component : appComponents(componentType);
}
