import  React from 'react';

import ResponsiveList from 'javascript_lib/components/responsive_list';


export default function genericComponents(type, params) {
  switch(type) {
    case 'ResponsiveList':
      return (
        <ResponsiveList
          listItems={params.list_items}
          breakPoints={params.break_points}
          listItemClassName={params.list_item_class}
          byColumnsAndRows={params.by_columns_and_rows ? true : false}
        />
      );
    default:
      return null;
  }
}
